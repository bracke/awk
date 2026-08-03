with AUnit.Assertions;

with Ada.Strings.Unbounded;

with Awk_Tests.Process_Harness;
with Awk_Tests.Process_Support;
with Project_Tools.Files;
with Project_Tools.Text;

package body Awk_Tests.Process_Language is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Multiple_Files (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 3) :=
        [new String'("{ print FILENAME "":"" FNR "":"" $1 }"),
         new String'("tests/fixtures/input/basic.txt"),
         new String'("tests/fixtures/input/second.txt")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process multiple files",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process multiple files exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "tests/fixtures/input/basic.txt:1:one"),
              "first file FILENAME/FNR visible");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "tests/fixtures/input/second.txt:1:five"),
              "second file FILENAME/FNR visible");
   end Test_Process_Multiple_Files;

   procedure Test_Process_Regex_Arithmetic_And_Builtins
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("/^[a-z]+ [0-9]+$/ { print $1, $2 + 3, substr($1, 2, 2), length($1) }"),
         new String'("tests/fixtures/input/regex_numbers.txt")];
      Status : Integer;
   begin
      Project_Tools.Files.Write_Raw_File
        ("../tests/fixtures/input/regex_numbers.txt",
         "alpha 7" & LF &
         "skip me" & LF &
         "beta 11" & LF);
      Status :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process regex arithmetic builtins",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
      Assert (Status = 0, "process regex arithmetic builtins exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "alpha 10 lp 5"),
              "regex pattern, arithmetic, substr, and length process first record");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "beta 14 et 4"),
              "regex pattern, arithmetic, substr, and length process second record");
      Assert (not Project_Tools.Text.Contains (U.To_String (Output), "skip"),
              "non-matching process input is not emitted");
      Project_Tools.Files.Delete_File_If_Present ("../tests/fixtures/input/regex_numbers.txt");
   end Test_Process_Regex_Arithmetic_And_Builtins;

   procedure Test_Process_Printf_Formatting
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("BEGIN { printf ""%s:%03d\n"", ""n"", 7 }")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process printf formatting",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process printf formatting exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "n:007"),
              "process printf formatted text is forwarded");
   end Test_Process_Printf_Formatting;

   procedure Test_Process_Comparisons
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("BEGIN { if (""beta"" > ""alpha"") print ""string""; if (5 >= 3) print ""number""; if (""7"" == 7) print ""coerce"" }")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process comparisons",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process comparisons exit successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "string" & LF),
              "process string comparison is evaluated by awklib");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "number" & LF),
              "process numeric comparison is evaluated by awklib");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "coerce" & LF),
              "process mixed comparison follows awklib conversion behavior");
   end Test_Process_Comparisons;

   procedure Test_Process_Sub_Replacement
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("BEGIN { s = ""aa""; sub(/a|aa/, ""X"", s); print s }")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process sub replacement",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process sub replacement exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "X" & LF),
              "process sub replacement follows awklib regex behavior");
   end Test_Process_Sub_Replacement;

   procedure Test_Process_String_Builtins
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("BEGIN { s = ""banana""; print gsub(/a/, ""A"", s), s; print index(s, ""nA""), toupper(""Ada"") }")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process string builtins",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process string builtins exit successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "3 bAnAnA" & LF),
              "process gsub replacement count and result follow awklib behavior");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "3 ADA" & LF),
              "process index and toupper follow awklib behavior");
   end Test_Process_String_Builtins;

   procedure Test_Process_Split_Builtin
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("BEGIN { n = split(""a:b:c"", parts, "":""); print n, parts[2] }")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process split builtin",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process split builtin exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "3 b" & LF),
              "process split populates array values through awklib");
   end Test_Process_Split_Builtin;

   procedure Test_Process_Match_And_Sprintf
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("BEGIN { print sprintf(""%s-%02d"", ""x"", 4); print match(""abc123"", /[0-9]+/), RSTART, RLENGTH }")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process match and sprintf",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process match and sprintf exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "x-04" & LF),
              "process sprintf result is forwarded");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "4 4 3" & LF),
              "process match updates RSTART and RLENGTH through awklib");
   end Test_Process_Match_And_Sprintf;

   procedure Test_Process_Output_Separators_And_Numeric_Builtins
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("BEGIN { OFS="":""; ORS=""|""; print tolower(""ADA""), int(3.9), sqrt(9) }")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process separators and numeric builtins",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process separators and numeric builtins exit successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "ada:3:3|"),
              "OFS, ORS, and numeric builtins are applied by awklib");
   end Test_Process_Output_Separators_And_Numeric_Builtins;

   procedure Test_Process_Math_Builtins
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("BEGIN { print sin(0), cos(0), exp(0), log(1), atan2(0, -1) }")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process math builtins",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process math builtins exit successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "0 1 1 0 3.14159" & LF),
              "process math builtins follow awklib output formatting");
   end Test_Process_Math_Builtins;

   procedure Test_Process_Arrays_Delete_And_While
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("BEGIN { a[""x""] = 1; a[""y""] = 2; delete a[""x""]; for (k in a) print k, a[k]; i = 0; while (i < 2) { print ""w"", i; i++ } }")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process arrays delete and while",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process arrays delete and while exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "y 2" & LF),
              "process array iteration observes deleted element");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "w 0" & LF),
              "process while loop emits first iteration");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "w 1" & LF),
              "process while loop emits second iteration");
      Assert (not Project_Tools.Text.Contains (U.To_String (Output), "x 1" & LF),
              "deleted array element is not emitted");
   end Test_Process_Arrays_Delete_And_While;

   procedure Test_Process_Next_Ternary_Break_And_Continue
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("BEGIN { for (i = 0; i < 4; i++) { if (i == 1) continue; if (i == 3) break; print ""loop"", i } } { if ($1 == ""one"") next; print (NF ? $1 : ""empty"") }"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process next ternary break continue",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process next ternary break continue exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "loop 0" & LF),
              "process for loop emits first retained iteration");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "loop 2" & LF),
              "process continue skips and break stops the loop");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "three" & LF),
              "process next skips the first input record");
      Assert (not Project_Tools.Text.Contains (U.To_String (Output), "one" & LF),
              "record skipped by next is not emitted");
   end Test_Process_Next_Ternary_Break_And_Continue;

   procedure Test_Process_Field_Assignment_Rebuilds_Record
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("BEGIN { FS="" ""; OFS=""|"" } { $2 = toupper($2); print $0, NF }"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process field assignment rebuilds record",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process field assignment rebuild exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "one|TWO|2" & LF),
              "first record is rebuilt by awklib after field assignment");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "three|FOUR|2" & LF),
              "second record is rebuilt by awklib after field assignment");
   end Test_Process_Field_Assignment_Rebuilds_Record;

   procedure Test_Process_Record_Assignment_Resplits_Fields
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("BEGIN { FS="" ""; OFS="":"" } { $0 = toupper($0); print $1, $2, NF }"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process record assignment resplits fields",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process record assignment resplit exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "ONE:TWO:2" & LF),
              "first record assignment is resplit by awklib");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "THREE:FOUR:2" & LF),
              "second record assignment is resplit by awklib");
   end Test_Process_Record_Assignment_Resplits_Fields;

   procedure Test_Process_Command_Getline (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("BEGIN { ""printf x"" | getline value; print value }")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process command getline",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process command getline exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "x"),
              "process command getline reads command output");
   end Test_Process_Command_Getline;

   procedure Test_Process_Auxiliary_File_Getline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("BEGIN { getline line < ""tests/fixtures/input/basic.txt""; print line }")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process auxiliary getline",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process auxiliary file getline exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "one two" & LF),
              "process getline < file reads registered host file");
   end Test_Process_Auxiliary_File_Getline;



   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Process_Multiple_Files'Access, "process multiple files");
      Registration.Register_Routine
        (T, Test_Process_Regex_Arithmetic_And_Builtins'Access,
         "process regex arithmetic builtins");
      Registration.Register_Routine
        (T, Test_Process_Printf_Formatting'Access,
         "process printf formatting");
      Registration.Register_Routine
        (T, Test_Process_Comparisons'Access,
         "process comparisons");
      Registration.Register_Routine
        (T, Test_Process_Sub_Replacement'Access,
         "process sub replacement");
      Registration.Register_Routine
        (T, Test_Process_String_Builtins'Access,
         "process string builtins");
      Registration.Register_Routine
        (T, Test_Process_Split_Builtin'Access,
         "process split builtin");
      Registration.Register_Routine
        (T, Test_Process_Match_And_Sprintf'Access,
         "process match and sprintf");
      Registration.Register_Routine
        (T, Test_Process_Output_Separators_And_Numeric_Builtins'Access,
         "process output separators and numeric builtins");
      Registration.Register_Routine
        (T, Test_Process_Math_Builtins'Access,
         "process math builtins");
      Registration.Register_Routine
        (T, Test_Process_Arrays_Delete_And_While'Access,
         "process arrays delete and while");
      Registration.Register_Routine
        (T, Test_Process_Next_Ternary_Break_And_Continue'Access,
         "process next ternary break continue");
      Registration.Register_Routine
        (T, Test_Process_Field_Assignment_Rebuilds_Record'Access,
         "process field assignment rebuilds record");
      Registration.Register_Routine
        (T, Test_Process_Record_Assignment_Resplits_Fields'Access,
         "process record assignment resplits fields");
      Registration.Register_Routine (T, Test_Process_Command_Getline'Access, "process command getline");
      Registration.Register_Routine
        (T, Test_Process_Auxiliary_File_Getline'Access,
         "process auxiliary file getline");
   end Register;
end Awk_Tests.Process_Language;
