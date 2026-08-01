package Awk_Catalog_Policy is
   function Required_Key_Count return Positive;
   function Required_Key (Index : Positive) return String
     with Pre => Index <= Required_Key_Count;

   function Placeholders (Text : String) return String;
   function Placeholder_Syntax_Ok (Text : String) return Boolean;

   function Failure_Message
     (Text             : String;
      Combined_Catalog : Boolean := True;
      Locale           : String := "") return String;
end Awk_Catalog_Policy;
