package Awk_Catalog_Policy is
   function Required_Key_Count return Positive;
   function Required_Key (Index : Positive) return String
     with Pre => Index <= Required_Key_Count;
   function Is_Required_Key (Key : String) return Boolean;

   function Supported_Locale_Count return Positive;
   function Supported_Locale (Index : Positive) return String
     with Pre => Index <= Supported_Locale_Count;
   function Is_Supported_Locale (Locale : String) return Boolean;

   function Placeholders (Text : String) return String;
   function Placeholder_Syntax_Ok (Text : String) return Boolean;

   function Failure_Message
     (Text             : String;
      Combined_Catalog : Boolean := True;
      Locale           : String := "") return String;
end Awk_Catalog_Policy;
