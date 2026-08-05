with AUnit.Assertions;

with Ada.Strings.Unbounded;

with Awk_CLI.Environment;
with Awk_CLI.Execution;
with Awk_CLI.Inputs;
with Awk_CLI.Operands;
with Awk_CLI.Options;
with Awk_CLI.Programs;
with Awk_Tests.Execution.Support;

package body Awk_Tests.Execution.Basic_Cases is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;
   package Support renames Awk_Tests.Execution.Support;

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
           Awk_CLI.Programs.Resolve (Parsed.Options, Support.Read_Test_File'Access);
         Ops    : constant Awk_CLI.Operands.Operand_Vectors.Vector :=
           Awk_CLI.Operands.Classify (Source.Source.Operands);
         Input  : constant Awk_CLI.Inputs.Load_Result :=
           Awk_CLI.Inputs.Load (Ops, "", Support.Read_Test_File'Access);
         Exec   : constant Awk_CLI.Execution.Execution_Result :=
           Awk_CLI.Execution.Execute
             (U.To_String (Source.Source.Text), Parsed.Options, Ops, Input.Files, Env);
      begin
         Assert (Exec.Ok, "execution succeeds");
         Assert
           (U.To_String (Exec.Standard_Output) = "8" & Support.LF,
            "-v visible before BEGIN");
         Assert
           (Awk_CLI.Execution.Supports_Streaming_Execution,
            "execution adapter exposes live awklib input callbacks");
      end;
   end Test_Execution;
end Awk_Tests.Execution.Basic_Cases;
