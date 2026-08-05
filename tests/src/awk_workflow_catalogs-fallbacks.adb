with Ada.Strings.Unbounded;

with Awk_Catalog_Policy;
with Project_Tools.Release_Checks;
with Project_Tools.Text;

package body Awk_Workflow_Catalogs.Fallbacks is
   package Text renames Project_Tools.Text;
   package U renames Ada.Strings.Unbounded;

   type Pattern_List is array (Positive range <>) of U.Unbounded_String;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Check_No_Fallbacks
      (Catalog    : String;
      Help_Keys  : Boolean;
      Banned     : Pattern_List;
      Message    : String)
   is
   begin
      for Locale_Index in 1 .. Awk_Catalog_Policy.Supported_Locale_Count loop
         declare
            Locale : constant String :=
              Awk_Catalog_Policy.Supported_Locale (Locale_Index);
         begin
            if Locale /= "en" then
               for Key_Index in 1 .. Awk_Catalog_Policy.Required_Key_Count loop
                  declare
                     Suffix : constant String :=
                       Awk_Catalog_Policy.Required_Key (Key_Index);
                  begin
                     if Text.Contains (Suffix, "awk.help.") = Help_Keys then
                        declare
                           Value : constant String :=
                             Text.Line_Value (Catalog, Locale & "." & Suffix);
                        begin
                           for Pattern of Banned loop
                              Require
                                (not Text.Contains (Value, U.To_String (Pattern)),
                                 Message & Locale & "." & Suffix);
                           end loop;
                        end;
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;
   end Check_No_Fallbacks;

   procedure Run (Catalog : String) is
      Help_Banned : constant Pattern_List :=
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
      Diagnostic_Banned : constant Pattern_List :=
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
      Check_No_Fallbacks
        (Catalog, True, Help_Banned,
         "non-English help catalog contains English fallback text: ");
      Check_No_Fallbacks
        (Catalog, False, Diagnostic_Banned,
         "non-English diagnostic catalog contains English fallback text: ");
   end Run;
end Awk_Workflow_Catalogs.Fallbacks;
