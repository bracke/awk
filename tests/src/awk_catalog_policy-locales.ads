package Awk_Catalog_Policy.Locales is
   function Count return Positive;
   function Item (Index : Positive) return String
     with Pre => Index <= Count;
   function Contains (Locale : String) return Boolean;
end Awk_Catalog_Policy.Locales;
