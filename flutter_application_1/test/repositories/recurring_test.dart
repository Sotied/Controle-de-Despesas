import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/repositories/accounts_repository.dart';
import 'package:flutter_application_1/src/repositories/recurring_entries_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AccountsRepository accountsRepository;
  late RecurringEntriesRepository recurringRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    accountsRepository = AccountsRepository(db);
    recurringRepository = RecurringEntriesRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertAccount() {
    return accountsRepository.createAccount(
      AccountsCompanion.insert(name: 'Banco', type: AccountType.bank),
    );
  }

  Future<List<FinancialEntry>> pendingEntries() {
    return (db.select(
      db.financialEntries,
    )..where((tbl) => tbl.status.equalsValue(EntryStatus.pending))).get();
  }

  test('gera ocorrências atrasadas e a próxima futura sem duplicidade', () async {
    final accountId = await insertAccount();
    final now = DateTime.now();

    final ruleId = await recurringRepository.create(
      RecurringEntriesCompanion.insert(
        description: 'Aluguel',
        type: EntryType.expense,
        amountCents: 150000,
        accountId: accountId,
        dayOfMonth: 1,
        startDate: DateTime(now.year, now.month - 2, 1),
      ),
    );

    final pending = await pendingEntries();
    expect(pending, hasLength(4));
    expect(pending.every((entry) => entry.recurringId == ruleId), isTrue);
    expect(pending.every((entry) => entry.dueAt != null), isTrue);
    expect(pending.every((entry) => entry.sourceAccountId == accountId), isTrue);
    expect(pending.every((entry) => entry.amountCents == 150000), isTrue);

    await recurringRepository.generateDueInstances();

    final after = await pendingEntries();
    expect(after, hasLength(4));

    final rule = await recurringRepository.findById(ruleId);
    expect(rule!.lastGeneratedDueAt, isNotNull);
  });

  test('confirma vencimento pendente', () async {
    final accountId = await insertAccount();
    final now = DateTime.now();

    await recurringRepository.create(
      RecurringEntriesCompanion.insert(
        description: 'Streaming',
        type: EntryType.expense,
        amountCents: 2990,
        accountId: accountId,
        dayOfMonth: 1,
        startDate: DateTime(now.year, now.month, 1),
      ),
    );

    final pending = await pendingEntries();
    expect(pending, hasLength(2));

    final currentMonth = pending.firstWhere(
      (entry) => entry.dueAt!.month == now.month,
    );

    await recurringRepository.confirmDueEntry(currentMonth.id);

    final updated = await (db.select(
      db.financialEntries,
    )..where((tbl) => tbl.id.equals(currentMonth.id))).getSingle();
    expect(updated.status, EntryStatus.completed);
    expect(updated.occurredAt, currentMonth.dueAt);
  });

  test('regra inativa não gera ocorrências', () async {
    final accountId = await insertAccount();
    final now = DateTime.now();

    await db
        .into(db.recurringEntries)
        .insert(
          RecurringEntriesCompanion.insert(
            description: 'Streaming',
            type: EntryType.expense,
            amountCents: 2990,
            accountId: accountId,
            dayOfMonth: 5,
            startDate: DateTime(now.year, now.month - 1, 5),
            active: const Value(false),
          ),
        );

    await recurringRepository.generateDueInstances();

    expect(await pendingEntries(), isEmpty);
  });

  test('excluir regra mantém lançamentos gerados e desvincula', () async {
    final accountId = await insertAccount();
    final now = DateTime.now();

    final ruleId = await recurringRepository.create(
      RecurringEntriesCompanion.insert(
        description: 'Aluguel',
        type: EntryType.expense,
        amountCents: 150000,
        accountId: accountId,
        dayOfMonth: 1,
        startDate: DateTime(now.year, now.month - 1, 1),
      ),
    );

    expect(await pendingEntries(), hasLength(3));

    await recurringRepository.delete(ruleId);

    final entries = await db.select(db.financialEntries).get();
    expect(entries, hasLength(3));
    expect(entries.every((entry) => entry.recurringId == null), isTrue);

    expect(await recurringRepository.findById(ruleId), isNull);
  });

  test('pausar e retomar regra controla geração', () async {
    final accountId = await insertAccount();
    final now = DateTime.now();

    final ruleId = await recurringRepository.create(
      RecurringEntriesCompanion.insert(
        description: 'Aluguel',
        type: EntryType.expense,
        amountCents: 150000,
        accountId: accountId,
        dayOfMonth: 1,
        startDate: DateTime(now.year, now.month, 1),
      ),
    );

    expect(await pendingEntries(), hasLength(2));

    await recurringRepository.setActive(ruleId, active: false);
    await recurringRepository.generateDueInstances();
    expect(await pendingEntries(), hasLength(2));

    final entries = await db.select(db.financialEntries).get();
    for (final entry in entries) {
      await (db
          .delete(db.financialEntries)
          ..where((tbl) => tbl.id.equals(entry.id))).go();
    }

    await recurringRepository.setActive(ruleId, active: true);
    await recurringRepository.generateDueInstances();

    final afterResume = await pendingEntries();
    expect(afterResume, hasLength(1));
  });
}
