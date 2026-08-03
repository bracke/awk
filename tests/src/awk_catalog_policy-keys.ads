package Awk_Catalog_Policy.Keys is
   function Count return Positive;
   function Item (Index : Positive) return String
     with Pre => Index <= Count;
   function Contains (Key : String) return Boolean;
end Awk_Catalog_Policy.Keys;
