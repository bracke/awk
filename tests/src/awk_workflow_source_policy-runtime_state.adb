with Ada.Strings.Unbounded;

with Project_Tools.Ada_Source;
with Project_Tools.Files;

package body Awk_Workflow_Source_Policy.Runtime_State is
   package Ada_Source renames Project_Tools.Ada_Source;
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

   procedure Run is
   begin
      Files.Require_Contains
        ("../src/library/awk_cli-inputs-live-reading.adb",
         "U.Slice (State.Active_Content",
         "in-memory live input chunking must avoid full-content copies",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-inputs-live-activation.adb",
         "procedure Close_Active_Input",
         "live input state-machine close/reset logic must be centralized",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-inputs-live-activation.adb",
         "function Activate_Operand",
         "live input operand activation must be centralized",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-context_io.adb",
         "procedure Record_Write",
         "context redirection write recording must be centralized",
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli-context_io.adb",
         [U.To_Unbounded_String ("Context.IO.Files.Element (Position).Openable"),
          U.To_Unbounded_String ("Context.IO.Files.Element (Position).Writable")],
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-inputs-live-activation.adb",
         "Awk_CLI.Context_IO.Read_Virtual_File",
         "live input must reuse centralized virtual-file read rules",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-context_io.adb",
         "File : constant Context_State.Virtual_File :=",
         "context redirection lookup must use a local virtual-file record",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-context_io.adb",
         "function Write_Existing_Process_File",
         "existing process redirection writes must be isolated in a named helper",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-context_io.adb",
         "function Write_New_Process_File",
         "new process redirection writes must be isolated in a named helper",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli.adb",
         "function Emit_CLI_Standard_Output",
         "top-level CLI stdout status handling must be centralized",
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli-inputs-live-reading.adb",
         [U.To_Unbounded_String ("U.To_String (State.Active_Content)")],
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens_In_Tree
        ("../src",
         [U.To_Unbounded_String ("Read_Standard_Input")],
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli.ads",
         "Default_Catalog_Path : constant String",
         "default catalog path must be centralized in the invocation context spec",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli.ads",
         "Default_Locale : constant String",
         "default locale must be centralized in the invocation context spec",
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli.adb",
         [U.To_Unbounded_String ("""resources/messages/catalog.txt"""),
          U.To_Unbounded_String ("""en""")],
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli.adb",
         "Context.Config := (others => <>);",
         "invocation configuration reset must use record defaults",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli.adb",
         "Context.IO := (others => <>);",
         "invocation I/O reset must use record defaults",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli.adb",
         "Context.Last_Diagnostic := (others => <>);",
         "diagnostic state reset must use record defaults",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-options.ads",
         "package String_Vectors renames Awk_CLI.String_Vectors;",
         "option parser must reuse the invocation argument vector type",
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli.adb",
         [U.To_Unbounded_String ("Parsed_Arguments")],
         Quiet => True);
   end Run;
end Awk_Workflow_Source_Policy.Runtime_State;
