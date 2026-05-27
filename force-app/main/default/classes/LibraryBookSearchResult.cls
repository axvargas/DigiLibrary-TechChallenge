public with sharing class LibraryBookSearchResult {
    @AuraEnabled public Id bookId;
    @AuraEnabled public String title;
    @AuraEnabled public String author;
    @AuraEnabled public Decimal availableCopies;
    @AuraEnabled public Decimal totalCopies;
    @AuraEnabled public String source;
    @AuraEnabled public Boolean existsInSalesforce;

    public LibraryBookSearchResult(
        Id bookId,
        String title,
        String author,
        Decimal availableCopies,
        Decimal totalCopies,
        String source,
        Boolean existsInSalesforce
    ) {
        this.bookId = bookId;
        this.title = title;
        this.author = author;
        this.availableCopies = availableCopies;
        this.totalCopies = totalCopies;
        this.source = source;
        this.existsInSalesforce = existsInSalesforce;
    }
}