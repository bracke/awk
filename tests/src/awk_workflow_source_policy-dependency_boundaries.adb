with Ada.Strings.Unbounded;

with Project_Tools.Ada_Source;
with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Source_Policy.Dependency_Boundaries is
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
      Unexpected : U.Unbounded_String;
   begin
      Files.Require_Contains
        ("../src/library/awk_cli-execution.adb", "with Awklib",
         "execution adapter must bridge to awklib", Quiet => True);
      Ada_Source.Require_Only_Allowed_With_Clauses
        ("../src/library/awk_cli-execution.adb",
         "Awklib",
         [U.To_Unbounded_String ("Awklib"),
          U.To_Unbounded_String ("Awklib.Interpreter")],
         Quiet => True);
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            "with Awklib.",
            Allowed_Files =>
              [U.To_Unbounded_String ("../src/library/awk_cli-execution.adb"),
               U.To_Unbounded_String ("src/library/awk_cli-execution.adb")]) = "",
         "only execution adapter may depend on awklib");

      Files.Require_Contains
        ("../src/library/awk_cli-localization.adb", "with Messages",
         "localization adapter must bridge to messages", Quiet => True);
      Ada_Source.Require_Only_Allowed_With_Clauses
        ("../src/library/awk_cli-localization.ads",
         "Messages",
         [U.To_Unbounded_String ("Messages.Runtime")],
         Quiet => True);
      Ada_Source.Require_Only_Allowed_With_Clauses
        ("../src/library/awk_cli-localization.adb",
         "Messages",
         [U.To_Unbounded_String ("Messages.Arguments"),
          U.To_Unbounded_String ("Messages.Result")],
         Quiet => True);
      Unexpected :=
        U.To_Unbounded_String
          (Ada_Source.First_Source_File_Containing
             ("../src",
              "with Messages",
              Allowed_Files =>
                [U.To_Unbounded_String ("../src/library/awk_cli-localization.adb"),
                 U.To_Unbounded_String ("../src/library/awk_cli-localization.ads")]));
      Require
        (U.To_String (Unexpected) = "",
         "only localization adapter may depend on messages: " & U.To_String (Unexpected));

      Files.Require_Contains
        ("../src/library/awk_cli-output.adb", "with Terminal_Styles",
         "presentation layer must bridge to terminal_styles", Quiet => True);
      Ada_Source.Require_Only_Allowed_With_Clauses
        ("../src/library/awk_cli-output.adb",
         "Terminal_Styles",
         [U.To_Unbounded_String ("Terminal_Styles")],
         Quiet => True);
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            "with Terminal_Styles",
            Allowed_Files =>
              [U.To_Unbounded_String ("../src/library/awk_cli-output.adb")]) = "",
         "only presentation layer may depend on terminal_styles");

      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb", "with Hostkit",
         "platform adapter must bridge to hostkit", Quiet => True);
      Ada_Source.Require_Only_Allowed_With_Clauses
        ("../src/library/awk_cli-platform.adb",
         "Hostkit",
         [U.To_Unbounded_String ("Hostkit"),
          U.To_Unbounded_String ("Hostkit.Fs"),
          U.To_Unbounded_String ("Hostkit.Host"),
          U.To_Unbounded_String ("Hostkit.Process"),
          U.To_Unbounded_String ("Hostkit.Shell")],
         Quiet => True);
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            "with Hostkit",
            Allowed_Files =>
              [U.To_Unbounded_String ("../src/library/awk_cli-platform.adb"),
               U.To_Unbounded_String ("src/library/awk_cli-platform.adb")]) = "",
         "only platform adapter may depend on hostkit");

      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            "Ada.Text_IO.Put",
            Allowed_Files =>
              [U.To_Unbounded_String ("../src/main/awk.adb"),
               U.To_Unbounded_String ("../src/library/awk_cli-platform.adb"),
               U.To_Unbounded_String ("src/main/awk.adb"),
               U.To_Unbounded_String ("src/library/awk_cli-platform.adb")]) = "",
         "direct Text_IO writes must stay in main containment or platform adapter");
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            "Ada.Command_Line",
            Allowed_Files =>
              [U.To_Unbounded_String ("../src/main/awk.adb"),
               U.To_Unbounded_String ("../src/library/awk_cli-platform.adb"),
               U.To_Unbounded_String ("src/main/awk.adb"),
               U.To_Unbounded_String ("src/library/awk_cli-platform.adb")]) = "",
         "process command-line access must stay in main containment or platform adapter");
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            "Ada.Environment_Variables",
            Allowed_Files =>
              [U.To_Unbounded_String ("../src/library/awk_cli-platform.adb"),
               U.To_Unbounded_String ("src/library/awk_cli-platform.adb")]) = "",
         "process environment access must stay in platform adapter");
   end Run;
end Awk_Workflow_Source_Policy.Dependency_Boundaries;
