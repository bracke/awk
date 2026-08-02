with AUnit.Assertions;

with Ada.Containers;
with Ada.Strings.Unbounded;

with Awk_CLI.Diagnostics;
with Awk_CLI.Options;

package body Awk_Tests.CLI_Options is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   use type Ada.Containers.Count_Type;
   use type Awk_CLI.Diagnostics.Exit_Code;
   use type Opt.Color_Mode;

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk cli options");
   end Name;

   procedure Test_Options (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("-F,"));
      Args.Append (U.To_Unbounded_String ("-v"));
      Args.Append (U.To_Unbounded_String ("name=a=b"));
      Args.Append (U.To_Unbounded_String ("{ print $1 }"));
      Args.Append (U.To_Unbounded_String ("--"));
      Args.Append (U.To_Unbounded_String ("-file"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (Result.Ok, "parse succeeds");
         Assert (Result.Options.Has_Field_Separator, "FS present");
         Assert (U.To_String (Result.Options.Field_Separator) = ",", "attached -F");
         Assert (Result.Options.Initial_Assignments.Length = 1, "-v retained");
         Assert (Result.Options.Operands.Length = 3, "operands retained after direct program");
         Assert (U.To_String (Result.Options.Operands.Element (2).Text) = "--",
                 "-- after direct program is an operand");
      end;
   end Test_Options;

   procedure Test_Bad_Options (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("--color=sometimes"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (not Result.Ok, "bad color rejected");
         Assert (Awk_CLI.Diagnostics.Status_For (Result.Diagnostic) = Awk_CLI.Diagnostics.Usage_Exit,
                 "bad color is usage");
      end;
   end Test_Bad_Options;

   procedure Test_Empty_Arguments_Report_Missing_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (not Result.Ok, "empty argument vector is a usage failure");
         Assert
           (Awk_CLI.Diagnostics.Status_For (Result.Diagnostic) =
            Awk_CLI.Diagnostics.Usage_Exit,
            "empty argument vector exits with usage status");
      end;
   end Test_Empty_Arguments_Report_Missing_Program;

   procedure Test_Option_Matrix (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("-F"));
      Args.Append (U.To_Unbounded_String (":"));
      Args.Append (U.To_Unbounded_String ("-F,"));
      Args.Append (U.To_Unbounded_String ("-vempty="));
      Args.Append (U.To_Unbounded_String ("-v"));
      Args.Append (U.To_Unbounded_String ("path=a=b"));
      Args.Append (U.To_Unbounded_String ("--color=always"));
      Args.Append (U.To_Unbounded_String ("--color=never"));
      Args.Append (U.To_Unbounded_String ("{ print }"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (Result.Ok, "option matrix parses");
         Assert (U.To_String (Result.Options.Field_Separator) = ",", "final -F wins");
         Assert (Result.Options.Initial_Assignments.Length = 2, "both -v assignments retained");
         Assert (U.To_String (Result.Options.Initial_Assignments.Element (1).Name) = "empty",
                 "empty assignment name preserved");
         Assert (U.To_String (Result.Options.Initial_Assignments.Element (1).Value) = "",
                 "empty assignment value preserved");
         Assert (U.To_String (Result.Options.Initial_Assignments.Element (2).Value) = "a=b",
                 "multiple equals preserved in value");
         Assert (Result.Options.Color = Opt.Color_Never, "final color wins");
      end;
   end Test_Option_Matrix;

   procedure Test_Option_Order_And_Index_Preservation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("-vA=1"));
      Args.Append (U.To_Unbounded_String ("-f"));
      Args.Append (U.To_Unbounded_String ("a.awk"));
      Args.Append (U.To_Unbounded_String ("-v"));
      Args.Append (U.To_Unbounded_String ("B=2"));
      Args.Append (U.To_Unbounded_String ("--"));
      Args.Append (U.To_Unbounded_String ("-dash"));
      Args.Append (U.To_Unbounded_String ("C=3"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (Result.Ok, "indexed option parse succeeds");
         Assert (Result.Options.Initial_Assignments.Length = 2, "initial assignments retained");
         Assert (Result.Options.Initial_Assignments.Element (1).Original_Index = 1,
                 "attached -v original index retained");
         Assert (Result.Options.Program_Files.Element (1).Original_Index = 3,
                 "program file original index retained");
         Assert (Result.Options.Initial_Assignments.Element (2).Original_Index = 5,
                 "separate -v value original index retained");
         Assert (Result.Options.Operands.Element (1).Original_Index = 7,
                 "operand after -- original index retained");
         Assert (U.To_String (Result.Options.Operands.Element (1).Text) = "-dash",
                 "dash-leading operand after -- is preserved");
         Assert (Result.Options.Operands.Element (2).Original_Index = 8,
                 "assignment operand original index retained");
      end;
   end Test_Option_Order_And_Index_Preservation;

   procedure Test_Option_Terminator_Treats_Long_Options_As_Operands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("--"));
      Args.Append (U.To_Unbounded_String ("--help"));
      Args.Append (U.To_Unbounded_String ("--version"));
      Args.Append (U.To_Unbounded_String ("--color=always"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (Result.Ok, "terminator parse succeeds");
         Assert (not Result.Options.Help_Requested,
                 "--help after -- is an operand, not a help request");
         Assert (not Result.Options.Version_Requested,
                 "--version after -- is an operand, not a version request");
         Assert (Result.Options.Color = Opt.Color_Auto,
                 "--color after -- does not change parser color policy");
         Assert (Result.Options.Operands.Length = 3,
                 "all long-option-looking arguments after -- are operands");
         Assert (U.To_String (Result.Options.Operands.Element (1).Text) = "--help",
                 "first operand after -- is preserved");
         Assert (Result.Options.Operands.Element (1).Original_Index = 2,
                 "first operand after -- keeps original index");
         Assert (U.To_String (Result.Options.Operands.Element (3).Text) = "--color=always",
                 "color-looking operand after -- is preserved");
      end;
   end Test_Option_Terminator_Treats_Long_Options_As_Operands;

   procedure Test_Options_After_Direct_Program_Are_Operands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("BEGIN { print ARGV[1] }"));
      Args.Append (U.To_Unbounded_String ("--version"));
      Args.Append (U.To_Unbounded_String ("--color=always"));
      Args.Append (U.To_Unbounded_String ("-F"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (Result.Ok, "post-program option-looking operands parse");
         Assert (not Result.Options.Version_Requested,
                 "--version after direct program is an operand");
         Assert (Result.Options.Color = Opt.Color_Auto,
                 "--color after direct program does not alter color policy");
         Assert (Result.Options.Operands.Length = 4,
                 "direct program and later option-looking operands are retained");
         Assert (U.To_String (Result.Options.Operands.Element (2).Text) = "--version",
                 "post-program --version spelling is preserved");
         Assert (Result.Options.Operands.Element (2).Original_Index = 2,
                 "post-program operand index is preserved");
         Assert (U.To_String (Result.Options.Operands.Element (4).Text) = "-F",
                 "post-program -F spelling is preserved as an operand");
      end;
   end Test_Options_After_Direct_Program_Are_Operands;

   procedure Test_Options_After_File_Mode_Operand_Are_Operands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("-f"));
      Args.Append (U.To_Unbounded_String ("program.awk"));
      Args.Append (U.To_Unbounded_String ("input.txt"));
      Args.Append (U.To_Unbounded_String ("-vX=late"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (Result.Ok, "post-input option-looking operands parse");
         Assert (Result.Options.Program_Files.Length = 1, "program file retained");
         Assert (Result.Options.Initial_Assignments.Is_Empty,
                 "-v after first file-mode operand is not an initial assignment");
         Assert (Result.Options.Operands.Length = 2,
                 "file-mode operand and later option-looking operand are retained");
         Assert (U.To_String (Result.Options.Operands.Element (2).Text) = "-vX=late",
                 "post-input option-looking argument spelling is preserved");
         Assert (Result.Options.Operands.Element (2).Original_Index = 4,
                 "post-input option-looking argument index is preserved");
      end;
   end Test_Options_After_File_Mode_Operand_Are_Operands;

   procedure Test_Option_Failures (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      procedure Expect_Failure (Argument, Message : String) is
         Args : Opt.String_Vectors.Vector;
      begin
         Args.Append (U.To_Unbounded_String (Argument));
         declare
            Result : constant Opt.Parse_Result := Opt.Parse (Args);
         begin
            Assert (not Result.Ok, Message);
         end;
      end Expect_Failure;
   begin
      Expect_Failure ("-F", "missing -F value rejected");
      Expect_Failure ("-v", "missing -v value rejected");
      Expect_Failure ("-f", "missing -f value rejected");
      Expect_Failure ("-v1bad=x", "invalid attached -v rejected");
      Expect_Failure ("-f-", "-f - rejected");
      Expect_Failure ("--color", "missing --color assignment rejected");
      Expect_Failure ("--color=", "empty --color mode rejected");
   end Test_Option_Failures;

   procedure Test_Option_Failure_Color_Preservation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Expect_Color
        (Arguments : Opt.String_Vectors.Vector;
         Expected  : Opt.Color_Mode;
         Message   : String)
      is
         Result : constant Opt.Parse_Result := Opt.Parse (Arguments);
      begin
         Assert (not Result.Ok, Message & " is a parse failure");
         Assert (Result.Color = Expected, Message & " preserves color mode");
      end Expect_Color;
   begin
      declare
         Args : Opt.String_Vectors.Vector;
      begin
         Args.Append (U.To_Unbounded_String ("--bad-option"));
         Expect_Color (Args, Opt.Color_Auto, "default-color unknown option");
      end;

      declare
         Args : Opt.String_Vectors.Vector;
      begin
         Args.Append (U.To_Unbounded_String ("--color=always"));
         Args.Append (U.To_Unbounded_String ("--bad-option"));
         Expect_Color (Args, Opt.Color_Always, "color=always unknown option");
      end;

      declare
         Args : Opt.String_Vectors.Vector;
      begin
         Args.Append (U.To_Unbounded_String ("--color=always"));
         Args.Append (U.To_Unbounded_String ("-F"));
         Expect_Color (Args, Opt.Color_Always, "color=always missing -F argument");
      end;

      declare
         Args : Opt.String_Vectors.Vector;
      begin
         Args.Append (U.To_Unbounded_String ("--color=never"));
         Args.Append (U.To_Unbounded_String ("-v1bad=x"));
         Expect_Color (Args, Opt.Color_Never, "color=never invalid assignment");
      end;

      declare
         Args : Opt.String_Vectors.Vector;
      begin
         Args.Append (U.To_Unbounded_String ("--color=always"));
         Args.Append (U.To_Unbounded_String ("-f-"));
         Expect_Color (Args, Opt.Color_Always, "color=always rejected stdin program file");
      end;

      declare
         Args : Opt.String_Vectors.Vector;
      begin
         Args.Append (U.To_Unbounded_String ("--color=never"));
         Expect_Color (Args, Opt.Color_Never, "color=never missing program");
      end;
   end Test_Option_Failure_Color_Preservation;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Options'Access, "option parser");
      Registration.Register_Routine (T, Test_Bad_Options'Access, "usage diagnostics");
      Registration.Register_Routine
        (T, Test_Empty_Arguments_Report_Missing_Program'Access,
         "empty arguments report missing program");
      Registration.Register_Routine (T, Test_Option_Matrix'Access, "option matrix");
      Registration.Register_Routine
        (T, Test_Option_Order_And_Index_Preservation'Access,
         "option order and indexes");
      Registration.Register_Routine
        (T, Test_Option_Terminator_Treats_Long_Options_As_Operands'Access,
         "option terminator long operands");
      Registration.Register_Routine
        (T, Test_Options_After_Direct_Program_Are_Operands'Access,
         "options after direct program are operands");
      Registration.Register_Routine
        (T, Test_Options_After_File_Mode_Operand_Are_Operands'Access,
         "options after file-mode operand are operands");
      Registration.Register_Routine (T, Test_Option_Failures'Access, "option failures");
      Registration.Register_Routine
        (T, Test_Option_Failure_Color_Preservation'Access,
         "option failure color preservation");
   end Register_Tests;
end Awk_Tests.CLI_Options;
