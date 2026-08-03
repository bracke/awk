with AUnit.Assertions;

with Ada.Containers;
with Ada.Strings.Unbounded;

with Awk_CLI.Diagnostics;
with Awk_CLI.Options;

package body Awk_Tests.CLI_Options.Core_Cases is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   use type Ada.Containers.Count_Type;
   use type Awk_CLI.Diagnostics.Exit_Code;
   use type Opt.Color_Mode;

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
         Assert
           (Awk_CLI.Diagnostics.Status_For (Result.Diagnostic) =
            Awk_CLI.Diagnostics.Usage_Exit,
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
         Assert (Result.Options.Initial_Assignments.Length = 2,
                 "both -v assignments retained");
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
         Assert (Result.Options.Initial_Assignments.Length = 2,
                 "initial assignments retained");
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

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
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
   end Register;
end Awk_Tests.CLI_Options.Core_Cases;
