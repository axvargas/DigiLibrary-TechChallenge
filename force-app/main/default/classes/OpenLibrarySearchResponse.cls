public with sharing class OpenLibrarySearchResponse {
    public List<OpenLibraryBook> docs;

    public class OpenLibraryBook {
        public String title;
        public List<String> author_name;
    }
}