package body Awk_CLI.Compatibility is
   type Text_Access is access constant String;

   type Registry_Entry is record
      Id            : Text_Access;
      Area          : Compatibility_Area;
      Status        : Compatibility_Status;
      Description   : Text_Access;
      Source        : Text_Access;
      Documentation : Text_Access;
      Test_Reference : Text_Access;
   end record;

   Entries : constant array (Positive range <>) of Registry_Entry :=
     [(Id            => new String'("AWK-COMPAT-REGEX-001"),
       Area          => Regular_Expressions,
       Status        => Supported_With_Documented_Difference,
       Description   => new String'("regular-expression matching follows awklib and regexp behavior"),
       Source        => new String'("awklib 0.1.0 and regexp"),
       Documentation => new String'("docs/compatibility.md"),
       Test_Reference => new String'("context expressions regex builtins")),
      (Id            => new String'("AWK-COMPAT-GETLINE-001"),
       Area          => Getline,
       Status        => Unsupported_By_Awklib,
       Description   => new String'("main-input getline from BEGIN is inherited from awklib"),
       Source        => new String'("awklib 0.1.0"),
       Documentation => new String'("docs/compatibility.md"),
       Test_Reference => new String'("compatibility registry")),
      (Id            => new String'("AWK-COMPAT-GETLINE-002"),
       Area          => Getline,
       Status        => Unsupported_By_Awklib,
       Description   => new String'("command-pipe getline is not implemented by the CLI"),
       Source        => new String'("awklib 0.1.0"),
       Documentation => new String'("docs/compatibility.md"),
       Test_Reference => new String'("compatibility registry")),
      (Id            => new String'("AWK-COMPAT-UTF8-001"),
       Area          => Encoding,
       Status        => Supported_With_Documented_Difference,
       Description   => new String'("malformed UTF-8 handling is inherited from awklib"),
       Source        => new String'("awklib 0.1.0"),
       Documentation => new String'("docs/compatibility.md"),
       Test_Reference => new String'("compatibility registry")),
      (Id            => new String'("AWK-COMPAT-PRINTF-001"),
       Area          => Output_Formatting,
       Status        => Supported_With_Documented_Difference,
       Description   => new String'("printf %c field-width behavior is inherited from awklib"),
       Source        => new String'("awklib 0.1.0"),
       Documentation => new String'("docs/compatibility.md"),
       Test_Reference => new String'("compatibility registry")),
      (Id            => new String'("AWK-COMPAT-ASSIGNMENT-001"),
       Area          => Command_Line,
       Status        => Supported_With_Documented_Difference,
       Description   => new String'("positional runtime assignment execution cannot be represented exactly"),
       Source        => new String'("awklib 0.1.0 Arguments API"),
       Documentation => new String'("docs/compatibility.md"),
       Test_Reference => new String'("context runtime assignment limitation")),
      (Id            => new String'("AWK-COMPAT-STREAMING-001"),
       Area          => Input,
       Status        => Supported_With_Documented_Difference,
       Description   => new String'("execution is memory-oriented rather than streaming"),
       Source        => new String'("CLI host input adapters over awklib 0.1.0 Run_Text_Streaming API"),
       Documentation => new String'("docs/compatibility.md"),
       Test_Reference => new String'("awklib execution adapter"))];

   function Count return Natural is (Entries'Length);

   function Id (Index : Positive) return String is (Entries (Index).Id.all);
   function Area (Index : Positive) return Compatibility_Area is (Entries (Index).Area);
   function Status (Index : Positive) return Compatibility_Status is (Entries (Index).Status);
   function Description (Index : Positive) return String is (Entries (Index).Description.all);
   function Source (Index : Positive) return String is (Entries (Index).Source.all);
   function Documentation (Index : Positive) return String is (Entries (Index).Documentation.all);
   function Test_Reference (Index : Positive) return String is (Entries (Index).Test_Reference.all);

   function Has_Id (Value : String) return Boolean is
   begin
      for Item of Entries loop
         if Item.Id.all = Value then
            return True;
         end if;
      end loop;
      return False;
   end Has_Id;
end Awk_CLI.Compatibility;
