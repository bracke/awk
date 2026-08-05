with AUnit.Assertions;

with Ada.Strings.Unbounded;

with Awk_CLI.Environment;
with Awk_CLI.Execution;
with Awk_CLI.Inputs;
with Awk_CLI.Operands;
with Awk_CLI.Options;
with Awk_CLI.Programs;
with Awk_Tests.Execution.Support;

package body Awk_Tests.Execution.Live_Cases is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;
   package Support renames Awk_Tests.Execution.Support;

   procedure Test_Live_Callbacks (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : Opt.String_Vectors.Vector;
      Env    : Awk_CLI.Environment.Entry_Vectors.Vector;
      State  : aliased Support.Live_State;
   begin
      Args.Append
        (U.To_Unbounded_String
           ("{ print $2; print ""saved"" > ""out.txt""; print ""again"" >> ""out.txt"" }"));

      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve (Parsed.Options, Support.Read_Test_File'Access);
         Ops    : constant Awk_CLI.Operands.Operand_Vectors.Vector :=
           Awk_CLI.Operands.Classify (Source.Source.Operands);
         Input  : constant Awk_CLI.Inputs.Load_Result :=
           Awk_CLI.Inputs.Load (Ops, "one two" & Support.LF, Support.Read_Test_File'Access);
         Exec   : constant Awk_CLI.Execution.Execution_Result :=
           Awk_CLI.Execution.Execute_Live
             (U.To_String (Source.Source.Text),
              Parsed.Options, Ops, Input.Files, Env,
              Support.Live_Output'Access, Support.Live_Redirection'Access,
              User_Data => State'Address);
      begin
         Assert (Exec.Ok, "live execution succeeds");
         Assert
           (U.To_String (Exec.Standard_Output) = "",
            "live stdout is not captured in execution result");
         Assert
           (Exec.Redirections.Is_Empty,
            "live redirection writes are not captured in execution result");
         Assert
           (U.To_String (State.Output) = "two" & Support.LF,
            "live stdout callback receives AWK output exactly");
         Assert
           (U.To_String (State.Redirection_Log) =
            "out.txt:write:saved" & Support.LF & "out.txt:append:again" & Support.LF,
            "live redirection callback receives append mode and content");
      end;
   end Test_Live_Callbacks;

   procedure Test_Live_Output_Failure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : Opt.String_Vectors.Vector;
      Env    : Awk_CLI.Environment.Entry_Vectors.Vector;
      State  : aliased Support.Live_State :=
        (Output => U.Null_Unbounded_String,
         Redirection_Log => U.Null_Unbounded_String,
         Fail_Output => True,
         Fail_Redirect => False);
   begin
      Args.Append (U.To_Unbounded_String ("BEGIN { print ""x"" }"));

      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve (Parsed.Options, Support.Read_Test_File'Access);
         Ops    : constant Awk_CLI.Operands.Operand_Vectors.Vector :=
           Awk_CLI.Operands.Classify (Source.Source.Operands);
         Input  : constant Awk_CLI.Inputs.Load_Result :=
           Awk_CLI.Inputs.Load (Ops, "", Support.Read_Test_File'Access);
         Exec   : constant Awk_CLI.Execution.Execution_Result :=
           Awk_CLI.Execution.Execute_Live
             (U.To_String (Source.Source.Text),
              Parsed.Options, Ops, Input.Files, Env,
              Support.Live_Output'Access, Support.Live_Redirection'Access,
              User_Data => State'Address);
      begin
         Assert (not Exec.Ok, "live stdout failure is reported");
         Assert
           (U.To_String (Exec.Diagnostic.Message_Id) = "awk.standard_output.write_failed",
            "live stdout failure uses standard output diagnostic");
      end;
   end Test_Live_Output_Failure;
end Awk_Tests.Execution.Live_Cases;
