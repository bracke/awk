with Awk_Catalog_Policy.Keys;
with Awk_Catalog_Policy.Locales;
with Awk_Catalog_Policy.Placeholder_Parsing;
with Awk_Catalog_Policy.Validation;

package body Awk_Catalog_Policy is
   function Required_Key_Count return Positive is
   begin
      return Awk_Catalog_Policy.Keys.Count;
   end Required_Key_Count;

   function Required_Key (Index : Positive) return String is
   begin
      return Awk_Catalog_Policy.Keys.Item (Index);
   end Required_Key;

   function Is_Required_Key (Key : String) return Boolean is
   begin
      return Awk_Catalog_Policy.Keys.Contains (Key);
   end Is_Required_Key;

   function Supported_Locale_Count return Positive is
   begin
      return Awk_Catalog_Policy.Locales.Count;
   end Supported_Locale_Count;

   function Supported_Locale (Index : Positive) return String is
   begin
      return Awk_Catalog_Policy.Locales.Item (Index);
   end Supported_Locale;

   function Is_Supported_Locale (Locale : String) return Boolean is
   begin
      return Awk_Catalog_Policy.Locales.Contains (Locale);
   end Is_Supported_Locale;

   function Placeholders (Text : String) return String is
   begin
      return Awk_Catalog_Policy.Placeholder_Parsing.Placeholders (Text);
   end Placeholders;

   function Placeholder_Syntax_Ok (Text : String) return Boolean is
   begin
      return Awk_Catalog_Policy.Placeholder_Parsing.Syntax_Ok (Text);
   end Placeholder_Syntax_Ok;

   function Failure_Message
     (Text             : String;
      Combined_Catalog : Boolean := True;
      Locale           : String := "") return String
   is
   begin
      return Awk_Catalog_Policy.Validation.Failure_Message
        (Text, Combined_Catalog, Locale);
   end Failure_Message;
end Awk_Catalog_Policy;
