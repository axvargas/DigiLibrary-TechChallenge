trigger LibraryBookLoanTrigger on Library_Book_Loan__c (
    before insert,
    before update,
    after insert,
    after update,
    after delete
) {
    LibraryBookLoanTriggerHandler.run(
        Trigger.operationType,
        Trigger.new,
        Trigger.old,
        Trigger.oldMap
    );
}