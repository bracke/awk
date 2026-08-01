package Awk_CLI.Compatibility is
   type Compatibility_Status is
     (Supported,
      Supported_With_Documented_Difference,
      Unsupported_By_Awklib,
      CLI_Specific);

   type Compatibility_Area is
     (Command_Line,
      Lexical_Syntax,
      Grammar,
      Expressions,
      Regular_Expressions,
      Fields_And_Records,
      Built_In_Variables,
      Built_In_Functions,
      Getline,
      Redirection,
      Input,
      Output_Formatting,
      Encoding);

   function Count return Natural;
   function Id (Index : Positive) return String with Pre => Index <= Count;
   function Area (Index : Positive) return Compatibility_Area with Pre => Index <= Count;
   function Status (Index : Positive) return Compatibility_Status with Pre => Index <= Count;
   function Description (Index : Positive) return String with Pre => Index <= Count;
   function Source (Index : Positive) return String with Pre => Index <= Count;
   function Documentation (Index : Positive) return String with Pre => Index <= Count;
   function Has_Id (Value : String) return Boolean;
end Awk_CLI.Compatibility;
