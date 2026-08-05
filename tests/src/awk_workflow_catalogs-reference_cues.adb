with Awk_Catalog_Policy;
with Project_Tools.Files;
with Project_Tools.Release_Checks;
with Project_Tools.Text;

package body Awk_Workflow_Catalogs.Reference_Cues is
   package Files renames Project_Tools.Files;
   package Text renames Project_Tools.Text;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Require_Reference_Cue (Catalog, Suffix, Cue : String) is
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
            Locale : constant String :=
              Awk_Catalog_Policy.Supported_Locale (Locale_Index);
            Value  : constant String := Text.Line_Value (Catalog, Locale & "." & Suffix);
         begin
            Require
              (Text.Contains (Value, Cue),
               "catalog entry missing reference cue " & Cue & ": "
               & Locale & "." & Suffix);
         end;
      end loop;
   end Require_Reference_Cue;

   procedure Run (Catalog : String) is
   begin
      Require_Reference_Cue (Catalog, "awk.help.summary", "awk");
      Require_Reference_Cue (Catalog, "awk.help.summary", "awklib");
      Require_Reference_Cue (Catalog, "awk.help.summary", "POSIX");
      Require_Reference_Cue (Catalog, "awk.help.usage.direct_program", "awk");
      Require_Reference_Cue (Catalog, "awk.help.usage.program_files", "awk");
      Require_Reference_Cue (Catalog, "awk.help.usage.program_files", "-f");
      Require_Reference_Cue (Catalog, "awk.help.options.field_separator", "-F");
      Require_Reference_Cue (Catalog, "awk.help.options.field_separator", "FS");
      Require_Reference_Cue (Catalog, "awk.help.options.variable", "-v");
      Require_Reference_Cue (Catalog, "awk.help.options.variable", "BEGIN");
      Require_Reference_Cue (Catalog, "awk.help.options.program_file", "-f");
      Require_Reference_Cue (Catalog, "awk.help.options.program_file", "AWK");
      Require_Reference_Cue
        (Catalog, "awk.help.options.color", "--color=auto|always|never");
      Require_Reference_Cue (Catalog, "awk.help.options.help", "--help");
      Require_Reference_Cue (Catalog, "awk.help.options.version", "--version");
      Require_Reference_Cue (Catalog, "awk.help.options.terminator", "--");
      Require_Reference_Cue (Catalog, "awk.help.operands", "-");
      Require_Reference_Cue (Catalog, "awk.help.operands", "[A-Za-z_][A-Za-z0-9_]*");
      Require_Reference_Cue (Catalog, "awk.help.stdin", "-");
      Require_Reference_Cue (Catalog, "awk.help.exit_statuses", "0");
      Require_Reference_Cue (Catalog, "awk.help.exit_statuses", "1");
      Require_Reference_Cue (Catalog, "awk.help.exit_statuses", "2");
      Require_Reference_Cue (Catalog, "awk.help.exit_statuses", "3");
      Require_Reference_Cue (Catalog, "awk.help.exit_statuses", "70");
      Require_Reference_Cue
        (Catalog, "awk.help.compatibility.awklib_limitations", "POSIX");
      Require_Reference_Cue
        (Catalog, "awk.help.compatibility.awklib_limitations", "AWK");
      Require_Reference_Cue
        (Catalog, "awk.help.compatibility.awklib_limitations", "awklib");
      Require_Reference_Cue
        (Catalog, "awk.help.compatibility.awklib_limitations", "getline");
   end Run;
end Awk_Workflow_Catalogs.Reference_Cues;
