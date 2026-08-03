with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Awk_Catalog_Policy;
with Messages.Consistency;
with Project_Tools.Files;
with Project_Tools.Release_Checks;
with Project_Tools.Test_Fixtures;
with Project_Tools.Text;

package body Awk_Workflow_Catalogs is
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

   procedure Run is
      Catalog    : constant String := Fixtures.Read_Text_File ("../resources/messages/catalog.txt");
      English    : constant String := Fixtures.Read_Text_File ("../resources/messages/en/catalog.txt");
      Danish     : constant String := Fixtures.Read_Text_File ("../resources/messages/da/catalog.txt");

      procedure Require_Key (Key : String) is
      begin
         Require (Text.Contains (Catalog, Key & " ="), "message catalog missing key: " & Key);
         Require (Text.Line_Value (Catalog, Key) /= "",
                  "message catalog has empty key: " & Key);
      end Require_Key;

      procedure Require_Shard_Key (Shard, Key, Name : String) is
      begin
         Require (Text.Contains (Shard, Key & " ="),
                  Name & " catalog shard missing key: " & Key);
         Require (Text.Line_Value (Shard, Key) /= "",
                  Name & " catalog shard has empty key: " & Key);
      end Require_Shard_Key;

      procedure Require_Consistent_Translations is
         Tokens : constant Messages.Consistency.Token_Array :=
           [U.To_Unbounded_String ("awk"),
            U.To_Unbounded_String ("awklib"),
            U.To_Unbounded_String ("-F"),
            U.To_Unbounded_String ("-v"),
            U.To_Unbounded_String ("-f"),
            U.To_Unbounded_String ("--help"),
            U.To_Unbounded_String ("--version"),
            U.To_Unbounded_String ("--color"),
            U.To_Unbounded_String ("--"),
            U.To_Unbounded_String ("ARGV"),
            U.To_Unbounded_String ("ARGC"),
            U.To_Unbounded_String ("ENVIRON"),
            U.To_Unbounded_String ("BEGIN"),
            U.To_Unbounded_String ("END"),
            U.To_Unbounded_String ("getline"),
            U.To_Unbounded_String ("print"),
            U.To_Unbounded_String ("printf"),
            U.To_Unbounded_String ("POSIX"),
            U.To_Unbounded_String ("MIT")];
         Findings : Messages.Consistency.Report;
      begin
         Messages.Consistency.Check_File
           (Path     => "../resources/messages/catalog.txt",
            Verbatim => Tokens,
            Into     => Findings);

         for Index in 1 .. Findings.Count loop
            Ada.Text_IO.Put_Line
              (Ada.Text_IO.Standard_Error,
               ("translation consistency finding: "
                & Messages.Consistency.Image (Findings.Items (Index))));
         end loop;

         Require
           (Findings.Count = 0,
            "translation consistency check reported findings");

         Require
           (not Findings.Overflow,
            "translation consistency produced more findings than the report holds");
      end Require_Consistent_Translations;

      procedure Require_No_English_Help_Fallbacks is
         Banned : constant array (Positive range <>) of U.Unbounded_String :=
           [U.To_Unbounded_String ("Ada command-line AWK implementation"),
            U.To_Unbounded_String ("Operands after the program are named input files"),
            U.To_Unbounded_String ("If no input operand is present"),
            U.To_Unbounded_String ("Exit statuses: 0 success"),
            U.To_Unbounded_String ("This program does not claim complete POSIX conformance"),
            U.To_Unbounded_String ("getline behavior follows awklib."),
            U.To_Unbounded_String ("set FS before execution"),
            U.To_Unbounded_String ("final occurrence wins"),
            U.To_Unbounded_String ("assign a variable before BEGIN"),
            U.To_Unbounded_String ("kept in command-line order"),
            U.To_Unbounded_String ("read AWK source from a file"),
            U.To_Unbounded_String ("multiple files are concatenated"),
            U.To_Unbounded_String ("style CLI-owned help and diagnostics only"),
            U.To_Unbounded_String ("show this help and exit"),
            U.To_Unbounded_String ("show version information and exit"),
            U.To_Unbounded_String ("end option processing"),
            U.To_Unbounded_String ("filenames beginning with"),
            U.To_Unbounded_String ("POSIX awk workflow"),
            U.To_Unbounded_String ("awklib defines behavior"),
            U.To_Unbounded_String ("[options]"),
            U.To_Unbounded_String ("program-file"),
            U.To_Unbounded_String ("host I/O"),
            U.To_Unbounded_String ("AWK CLI"),
            U.To_Unbounded_String ("AWK-CLI"),
            U.To_Unbounded_String ("EOF"),
            U.To_Unbounded_String ("CLI"),
            U.To_Unbounded_String ("input standard"),
            U.To_Unbounded_String ("error AWK"),
            U.To_Unbounded_String ("AWK error"),
            U.To_Unbounded_String ("[operand...]"),
            U.To_Unbounded_String ("-f file, -ffile"),
            U.To_Unbounded_String ("-F sep, -Fsep"),
            U.To_Unbounded_String ("-v name=value, -vname=value"),
            U.To_Unbounded_String ("name=value")];
      begin
         for Locale_Index in 1 .. Awk_Catalog_Policy.Supported_Locale_Count loop
            declare
               Locale : constant String := Awk_Catalog_Policy.Supported_Locale (Locale_Index);
            begin
               if Locale /= "en" then
                  for Key_Index in 1 .. Awk_Catalog_Policy.Required_Key_Count loop
                     declare
                        Suffix : constant String := Awk_Catalog_Policy.Required_Key (Key_Index);
                     begin
                        if Text.Contains (Suffix, "awk.help.") then
                           declare
                              Value : constant String :=
                                Text.Line_Value (Catalog, Locale & "." & Suffix);
                           begin
                              for Pattern of Banned loop
                                 Require
                                   (not Text.Contains (Value, U.To_String (Pattern)),
                                    "non-English help catalog contains English fallback text: "
                                    & Locale & "." & Suffix);
                              end loop;
                           end;
                        end if;
                     end;
                  end loop;
               end if;
            end;
         end loop;
      end Require_No_English_Help_Fallbacks;

      procedure Require_No_English_Diagnostic_Fallbacks is
         Banned : constant array (Positive range <>) of U.Unbounded_String :=
           [U.To_Unbounded_String ("AWK parse failed"),
            U.To_Unbounded_String ("AWK execution failed"),
            U.To_Unbounded_String ("unsupported awklib operation"),
            U.To_Unbounded_String ("localization failed for message key"),
            U.To_Unbounded_String ("unknown option"),
            U.To_Unbounded_String ("missing argument"),
            U.To_Unbounded_String ("invalid assignment"),
            U.To_Unbounded_String ("invalid color mode"),
            U.To_Unbounded_String ("cannot open"),
            U.To_Unbounded_String ("cannot read"),
            U.To_Unbounded_String ("cannot write"),
            U.To_Unbounded_String ("use --help for command-line syntax"),
            U.To_Unbounded_String ("use -- before filenames that begin with"),
            U.To_Unbounded_String ("program file"),
            U.To_Unbounded_String ("input file"),
            U.To_Unbounded_String ("output file"),
            U.To_Unbounded_String ("standard input"),
            U.To_Unbounded_String ("standard output"),
            U.To_Unbounded_String ("is unsupported because"),
            U.To_Unbounded_String ("is reserved for AWK data"),
            U.To_Unbounded_String ("error: {"),
            U.To_Unbounded_String (" / {option}"),
            U.To_Unbounded_String ("hint: {detail}"),
            U.To_Unbounded_String ("AWK-data"),
            U.To_Unbounded_String ("input standard"),
            U.To_Unbounded_String ("AWK data"),
            U.To_Unbounded_String ("unexpected internal software failure")];
      begin
         for Locale_Index in 1 .. Awk_Catalog_Policy.Supported_Locale_Count loop
            declare
               Locale : constant String := Awk_Catalog_Policy.Supported_Locale (Locale_Index);
            begin
               if Locale /= "en" then
                  for Key_Index in 1 .. Awk_Catalog_Policy.Required_Key_Count loop
                     declare
                        Suffix : constant String := Awk_Catalog_Policy.Required_Key (Key_Index);
                     begin
                        if not Text.Contains (Suffix, "awk.help.") then
                           declare
                              Value : constant String :=
                                Text.Line_Value (Catalog, Locale & "." & Suffix);
                           begin
                              for Pattern of Banned loop
                                 Require
                                   (not Text.Contains (Value, U.To_String (Pattern)),
                                    "non-English diagnostic catalog contains English fallback text: "
                                    & Locale & "." & Suffix);
                              end loop;
                           end;
                        end if;
                     end;
                  end loop;
               end if;
            end;
         end loop;
      end Require_No_English_Diagnostic_Fallbacks;

      procedure Require_Reference_Cue (Suffix, Cue : String) is
      begin
         Files.Require_Contains
           ("../docs/localization-reference.md", Suffix,
            "localization reference missing cue " & Cue & " for " & Suffix,
            Quiet => True);
         Files.Require_Contains
           ("../docs/localization-reference.md", Cue,
            "localization reference missing cue " & Cue & " for " & Suffix,
            Quiet => True);

         for Locale_Index in 1 .. Awk_Catalog_Policy.Supported_Locale_Count loop
            declare
               Locale : constant String := Awk_Catalog_Policy.Supported_Locale (Locale_Index);
               Value  : constant String := Text.Line_Value (Catalog, Locale & "." & Suffix);
            begin
               Require
                 (Text.Contains (Value, Cue),
                  "catalog entry missing reference cue " & Cue & ": "
                  & Locale & "." & Suffix);
            end;
         end loop;
      end Require_Reference_Cue;

      procedure Require_Reference_Cues is
      begin
         Require_Reference_Cue ("awk.help.summary", "awk");
         Require_Reference_Cue ("awk.help.summary", "awklib");
         Require_Reference_Cue ("awk.help.summary", "POSIX");
         Require_Reference_Cue ("awk.help.usage.direct_program", "awk");
         Require_Reference_Cue ("awk.help.usage.program_files", "awk");
         Require_Reference_Cue ("awk.help.usage.program_files", "-f");
         Require_Reference_Cue ("awk.help.options.field_separator", "-F");
         Require_Reference_Cue ("awk.help.options.field_separator", "FS");
         Require_Reference_Cue ("awk.help.options.variable", "-v");
         Require_Reference_Cue ("awk.help.options.variable", "BEGIN");
         Require_Reference_Cue ("awk.help.options.program_file", "-f");
         Require_Reference_Cue ("awk.help.options.program_file", "AWK");
         Require_Reference_Cue ("awk.help.options.color", "--color=auto|always|never");
         Require_Reference_Cue ("awk.help.options.help", "--help");
         Require_Reference_Cue ("awk.help.options.version", "--version");
         Require_Reference_Cue ("awk.help.options.terminator", "--");
         Require_Reference_Cue ("awk.help.operands", "-");
         Require_Reference_Cue ("awk.help.operands", "[A-Za-z_][A-Za-z0-9_]*");
         Require_Reference_Cue ("awk.help.stdin", "-");
         Require_Reference_Cue ("awk.help.exit_statuses", "0");
         Require_Reference_Cue ("awk.help.exit_statuses", "1");
         Require_Reference_Cue ("awk.help.exit_statuses", "2");
         Require_Reference_Cue ("awk.help.exit_statuses", "3");
         Require_Reference_Cue ("awk.help.exit_statuses", "70");
         Require_Reference_Cue ("awk.help.compatibility.awklib_limitations", "POSIX");
         Require_Reference_Cue ("awk.help.compatibility.awklib_limitations", "AWK");
         Require_Reference_Cue ("awk.help.compatibility.awklib_limitations", "awklib");
         Require_Reference_Cue ("awk.help.compatibility.awklib_limitations", "getline");
      end Require_Reference_Cues;
   begin
      Require (Catalog /= "", "message catalog is missing or empty");
      Require (English /= "", "English catalog shard is missing or empty");
      Require (Danish /= "", "Danish catalog shard is missing or empty");

      Require
        (Awk_Catalog_Policy.Failure_Message (Catalog) = "",
         Awk_Catalog_Policy.Failure_Message (Catalog));
      Require
        (Awk_Catalog_Policy.Failure_Message
           (English, Combined_Catalog => False, Locale => "en") = "",
         Awk_Catalog_Policy.Failure_Message
           (English, Combined_Catalog => False, Locale => "en"));
      Require
        (Awk_Catalog_Policy.Failure_Message
           (Danish, Combined_Catalog => False, Locale => "da") = "",
         Awk_Catalog_Policy.Failure_Message
           (Danish, Combined_Catalog => False, Locale => "da"));

      for Index in 1 .. Awk_Catalog_Policy.Required_Key_Count loop
         declare
            Suffix : constant String := Awk_Catalog_Policy.Required_Key (Index);
         begin
            for Locale_Index in 1 .. Awk_Catalog_Policy.Supported_Locale_Count loop
               declare
                  Locale : constant String := Awk_Catalog_Policy.Supported_Locale (Locale_Index);
               begin
                  Require_Key (Locale & "." & Suffix);
                  Require
                    (Awk_Catalog_Policy.Placeholders (Text.Line_Value (Catalog, "en." & Suffix)) =
                     Awk_Catalog_Policy.Placeholders (Text.Line_Value (Catalog, Locale & "." & Suffix)),
                     "placeholder mismatch between en and " & Locale & " for " & Suffix);
               end;
            end loop;
            Require_Shard_Key (English, "en." & Suffix, "English");
            Require_Shard_Key (Danish, "da." & Suffix, "Danish");
         end;
      end loop;
      Require_Consistent_Translations;
      Require_No_English_Help_Fallbacks;
      Require_No_English_Diagnostic_Fallbacks;
      Require_Reference_Cues;
      Put_Info ("catalog checks passed");
   end Run;
end Awk_Workflow_Catalogs;
