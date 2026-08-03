with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Awk_CLI.Diagnostics;
with Project_Tools.Files;
with Project_Tools.Release_Checks;
with Project_Tools.Test_Fixtures;
with Project_Tools.Text;

package body Awk_Workflow_Drift is
   package D renames Awk_CLI.Diagnostics;
   package Files renames Project_Tools.Files;
   package Fixtures renames Project_Tools.Test_Fixtures;
   package Text renames Project_Tools.Text;
   package U renames Ada.Strings.Unbounded;

   procedure Put_Info (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Message);
   end Put_Info;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Exit_Statuses is
      Docs      : constant String := Fixtures.Read_Text_File ("../docs/diagnostics.md");
      Reference : constant String := Fixtures.Read_Text_File ("../docs/command-line-reference.md");
      Allowed   : U.Unbounded_String;

      function Image (Value : D.Exit_Code) return String is
         Raw : constant String := D.Exit_Code'Image (Value);
      begin
         if Raw'Length > 0 and then Raw (Raw'First) = ' ' then
            return Raw (Raw'First + 1 .. Raw'Last);
         else
            return Raw;
         end if;
      end Image;

      procedure Require_Exit (Name : String; Status : D.Exit_Code) is
         Value : constant String := Image (Status);
      begin
         U.Append (Allowed, " " & Value & " ");
         Require
           (Text.Contains (Docs, "| `" & Value & "` |"),
            "exit status " & Value & " from " & Name & " is not documented");
         Require
           (Text.Contains (Reference, "`" & Value & "`"),
            "exit status " & Value & " from " & Name
            & " is missing from the command-line reference");
      end Require_Exit;

      From : Positive := Docs'First;
   begin
      Require_Exit ("Success_Exit", D.Success_Exit);
      Require_Exit ("Interpreter_Exit", D.Interpreter_Exit);
      Require_Exit ("Usage_Exit", D.Usage_Exit);
      Require_Exit ("IO_Exit", D.IO_Exit);
      Require_Exit ("Internal_Exit", D.Internal_Exit);

      while From <= Docs'Last loop
         declare
            Mark : constant Natural := Text.Index_From (Docs, "| `", From);
            Stop : Natural;
         begin
            exit when Mark = 0;
            Stop := Mark + 3;
            while Stop <= Docs'Last and then Docs (Stop) in '0' .. '9' loop
               Stop := Stop + 1;
            end loop;
            if Stop > Mark + 3
              and then Stop <= Docs'Last
              and then Docs (Stop) = '`'
            then
               declare
                  Value : constant String := Docs (Mark + 3 .. Stop - 1);
               begin
                  Require
                    (Text.Contains (U.To_String (Allowed), " " & Value & " "),
                     "exit status " & Value & " is documented but not defined");
               end;
            end if;
            From := Mark + 3;
         end;
      end loop;
      Put_Info ("exit status drift checks passed");
   end Exit_Statuses;

   procedure Options is
      procedure Require_Option (Spelling : String) is
      begin
         Files.Require_Contains
           ("../docs/command-line-reference.md", Spelling,
            "command-line reference missing accepted option: " & Spelling,
            Quiet => True);
         Files.Require_Contains
           ("../resources/messages/catalog.txt", Spelling,
            "help catalog missing accepted option: " & Spelling,
            Quiet => True);
      end Require_Option;
   begin
      Require_Option ("-F");
      Require_Option ("-v");
      Require_Option ("-f");
      Require_Option ("--color");
      Require_Option ("--help");
      Require_Option ("--version");
      Require_Option ("--");
      Files.Require_Contains
        ("../docs/command-line-reference.md", "--color=auto|always|never",
         "color modes must stay documented in reference and help catalog",
         Quiet => True);
      Files.Require_Contains
        ("../resources/messages/catalog.txt", "--color=auto|always|never",
         "color modes must stay documented in reference and help catalog",
         Quiet => True);
      Files.Require_Contains
        ("../docs/quickstart.md", "awk '{ print $1 }'",
         "quickstart must document direct, -F, and -f invocation examples",
         Quiet => True);
      Files.Require_Contains
        ("../docs/quickstart.md", "awk -F:",
         "quickstart must document direct, -F, and -f invocation examples",
         Quiet => True);
      Files.Require_Contains
        ("../docs/quickstart.md", "awk -f script.awk",
         "quickstart must document direct, -F, and -f invocation examples",
         Quiet => True);
      Put_Info ("option drift checks passed");
   end Options;
end Awk_Workflow_Drift;
