with Ada.Strings.Unbounded;

with Project_Tools.Ada_Source;
with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Source_Policy.Presentation is
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
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli-output.adb",
         [U.To_Unbounded_String ("Character'Val (27)")],
         Quiet => True);
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            "Character'Val (27)",
            Allowed_Files =>
              [U.To_Unbounded_String ("../src/library/awk_cli-diagnostics.adb"),
               U.To_Unbounded_String ("src/library/awk_cli-diagnostics.adb")]) = "",
         "only diagnostic escaping may inspect the ESC character");
      Ada_Source.Require_No_Code_Tokens_In_Tree
        ("../src",
         [U.To_Unbounded_String ("Character'Val(27)"),
          U.To_Unbounded_String ("ASCII.ESC"),
          U.To_Unbounded_String ("Ada.Characters.Latin_1.ESC")],
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli-output.adb",
         [U.To_Unbounded_String ("""awk: """)],
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-output.adb",
         "Help_Lines : constant array",
         "help rendering must use a structured line registry",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-output.adb",
         "procedure Append_Help_Line",
         "help rendering must be centralized around registry items",
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli-programs.adb",
         [U.To_Unbounded_String ("""command line""")],
         Quiet => True);
   end Run;
end Awk_Workflow_Source_Policy.Presentation;
