with Awk_CLI.Localization;

package body Awk_Tests.Process_Support.Localization_Text is
   function Locale_Text
     (Key       : String;
      Locale    : String := "en";
      Name      : String := "";
      Value     : String := "";
      Detail    : String := "") return String
   is
      Catalog : Awk_CLI.Localization.Catalog;
   begin
      Awk_CLI.Localization.Initialize
        (Catalog, "../resources/messages/catalog.txt", Locale);
      return Awk_CLI.Localization.Text (Catalog, Key, Name, Value, Detail);
   end Locale_Text;

   function English_Text
     (Key       : String;
      Name      : String := "";
      Value     : String := "";
      Detail    : String := "") return String is
     (Locale_Text (Key, "en", Name, Value, Detail));

   function English_Hint (Hint_Key : String) return String is
   begin
      return English_Text
        ("awk.diagnostic.hint",
         Detail => English_Text (Hint_Key));
   end English_Hint;

   function English_Error_Header (Primary : String) return String is
   begin
      return English_Text
        ("awk.diagnostic.header",
         Name   => "severity",
         Value  => English_Text ("awk.diagnostic.label.error"),
         Detail => Primary);
   end English_Error_Header;
end Awk_Tests.Process_Support.Localization_Text;
