package Awk_Tests.Process_Support.Localization_Text is
   function Locale_Text
     (Key       : String;
      Locale    : String := "en";
      Name      : String := "";
      Value     : String := "";
      Detail    : String := "") return String;

   function English_Text
     (Key       : String;
      Name      : String := "";
      Value     : String := "";
      Detail    : String := "") return String;

   function English_Hint (Hint_Key : String) return String;
   function English_Error_Header (Primary : String) return String;
end Awk_Tests.Process_Support.Localization_Text;
