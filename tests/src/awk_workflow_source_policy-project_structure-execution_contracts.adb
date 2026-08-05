with Ada.Strings.Unbounded;

with Project_Tools.Ada_Source;
with Project_Tools.Files;

package body Awk_Workflow_Source_Policy.Project_Structure.Execution_Contracts is
   package Ada_Source renames Project_Tools.Ada_Source;
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

   procedure Run is
   begin
      Files.Require_Contains
        ("../src/library/awk_cli.adb", "procedure Record_Diagnostic",
         "top-level runner must centralize diagnostic state recording",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-execution-runner.adb", "function Build_Run_Result",
         "execution adapter must centralize awklib run-result conversion",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-execution-runner.adb",
         "Ada.Exceptions.Exception_Name",
         "execution internal diagnostics should retain sanitized exception identity",
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli-execution.adb",
         [U.To_Unbounded_String ("Exception_Information")],
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-inputs-live-initialize.adb",
         "Callback lifetime invariant: Context and Operands",
         "live input unchecked callback access must document object lifetimes",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-execution-runner.adb",
         "Callback lifetime invariant: Inputs, Output, Redirs, and State",
         "execution unchecked callback access must document object lifetimes",
         Quiet => True);
   end Run;
end Awk_Workflow_Source_Policy.Project_Structure.Execution_Contracts;
