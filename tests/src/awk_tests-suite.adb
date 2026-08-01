with AUnit.Assertions;
with AUnit.Test_Cases;

with Ada.Containers;
with Ada.Strings.Unbounded;

with Awk_CLI.Diagnostics;
with Awk_CLI.Environment;
with Awk_CLI.Execution;
with Awk_CLI.Inputs;
with Awk_CLI.Operands;
with Awk_CLI.Options;
with Awk_CLI.Programs;

package body Awk_Tests.Suite is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   LF : constant String := [1 => ASCII.LF];

   type CLI_Case is new AUnit.Test_Cases.Test_Case with null record;
   overriding procedure Register_Tests (T : in out CLI_Case);

   use type Ada.Containers.Count_Type;
   use type Awk_CLI.Diagnostics.Exit_Code;
   use type Awk_CLI.Operands.Operand_Kind;

   overriding function Name (T : CLI_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk cli");
   end Name;

   function Read_Test_File (Path : String; Content : out U.Unbounded_String) return Boolean is
   begin
      if Path = "a.awk" then
         Content := U.To_Unbounded_String ("BEGIN { print ""a"" }");
         return True;
      elsif Path = "b.awk" then
         Content := U.To_Unbounded_String ("BEGIN { print ""b"" }");
         return True;
      elsif Path = "input" then
         Content := U.To_Unbounded_String ("x y" & LF);
         return True;
      else
         Content := U.Null_Unbounded_String;
         return False;
      end if;
   end Read_Test_File;

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
         Assert (Result.Options.Operands.Length = 2, "operands retained after --");
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

   procedure Test_Program_Files (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("-f"));
      Args.Append (U.To_Unbounded_String ("a.awk"));
      Args.Append (U.To_Unbounded_String ("-fb.awk"));
      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve (Parsed.Options, Read_Test_File'Access);
      begin
         Assert (Source.Ok, "source resolves");
         Assert (U.To_String (Source.Source.Text) =
                 "BEGIN { print ""a"" }" & LF & "BEGIN { print ""b"" }",
                 "files are separated and ordered");
         Assert (Source.Source.Segments.Length = 2, "segments tracked");
      end;
   end Test_Program_Files;

   procedure Test_Operands (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Raw : Opt.Operand_Vectors.Vector;
   begin
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("input"), Original_Index => 1));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("-"), Original_Index => 2));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("name=a=b"), Original_Index => 3));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("./X=value"), Original_Index => 4));
      declare
         Items : constant Awk_CLI.Operands.Operand_Vectors.Vector := Awk_CLI.Operands.Classify (Raw);
      begin
         Assert (Items.Element (1).Kind = Awk_CLI.Operands.Named_File, "file");
         Assert (Items.Element (2).Kind = Awk_CLI.Operands.Standard_Input, "stdin");
         Assert (Items.Element (3).Kind = Awk_CLI.Operands.Runtime_Assignment, "assignment");
         Assert (Items.Element (4).Kind = Awk_CLI.Operands.Named_File, "path with equals is file");
      end;
   end Test_Operands;

   procedure Test_Execution (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : Opt.String_Vectors.Vector;
      Env    : Awk_CLI.Environment.Entry_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("-vX=7"));
      Args.Append (U.To_Unbounded_String ("BEGIN { print X + 1 }"));
      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve (Parsed.Options, Read_Test_File'Access);
         Ops    : constant Awk_CLI.Operands.Operand_Vectors.Vector :=
           Awk_CLI.Operands.Classify (Source.Source.Operands);
         Input  : constant Awk_CLI.Inputs.Load_Result :=
           Awk_CLI.Inputs.Load (Ops, "", Read_Test_File'Access);
         Exec   : constant Awk_CLI.Execution.Execution_Result :=
           Awk_CLI.Execution.Execute
             (U.To_String (Source.Source.Text), Parsed.Options, Ops, Input.Files, Env);
      begin
         Assert (Exec.Ok, "execution succeeds");
         Assert (U.To_String (Exec.Standard_Output) = "8" & LF, "-v visible before BEGIN");
      end;
   end Test_Execution;

   overriding procedure Register_Tests (T : in out CLI_Case) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Options'Access, "option parser");
      Registration.Register_Routine (T, Test_Bad_Options'Access, "usage diagnostics");
      Registration.Register_Routine (T, Test_Program_Files'Access, "program sources");
      Registration.Register_Routine (T, Test_Operands'Access, "operand classifier");
      Registration.Register_Routine (T, Test_Execution'Access, "awklib execution adapter");
   end Register_Tests;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Result : constant AUnit.Test_Suites.Access_Test_Suite := new AUnit.Test_Suites.Test_Suite;
   begin
      Result.Add_Test (new CLI_Case);
      return Result;
   end Suite;
end Awk_Tests.Suite;
