package Awk_Catalog_Policy.Validation is
   function Failure_Message
     (Text             : String;
      Combined_Catalog : Boolean := True;
      Locale           : String := "") return String;
end Awk_Catalog_Policy.Validation;
