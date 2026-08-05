with Ada.Strings.Unbounded;

with Project_Tools.Ada_Source;
with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Source_Policy.Project_Structure.Context_Contracts is
   package Ada_Source renames Project_Tools.Ada_Source;
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Run is
   begin
      Files.Require_Contains
        ("src/awk_cli-testing.ads", "package Awk_CLI.Testing",
         "in-memory invocation harness must live in the tests crate",
         Quiet => True);
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src/library",
            "package Awk_CLI.Testing") = "",
         "test harness child package must not live in production sources");
      Files.Require_Contains
        ("../src/library/awk_cli.ads", "type Invocation_Configuration is record",
         "invocation context must group process configuration state",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli_context_state.ads", "type Virtual_IO_State is record",
         "invocation context virtual I/O state must live in internal state storage",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli_context_state.ads", "type Diagnostic_State is record",
         "invocation context diagnostic state must live in internal state storage",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli.ads", "IO              : State.Virtual_IO_State;",
         "root context must depend on internal state storage by type only",
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli.ads",
         [U.To_Unbounded_String ("procedure Add_Argument"),
          U.To_Unbounded_String ("procedure Set_Standard_Input"),
          U.To_Unbounded_String ("procedure Add_File"),
          U.To_Unbounded_String ("procedure Add_Environment"),
          U.To_Unbounded_String ("function Standard_Output"),
          U.To_Unbounded_String ("function Written_File_Count")],
         Quiet => True);
   end Run;
end Awk_Workflow_Source_Policy.Project_Structure.Context_Contracts;
