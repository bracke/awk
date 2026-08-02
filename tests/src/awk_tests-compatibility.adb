with AUnit.Assertions;

with Awk_CLI.Compatibility;
with Project_Tools.Files;
with Project_Tools.Test_Fixtures;
with Project_Tools.Text;

package body Awk_Tests.Compatibility is
   use AUnit.Assertions;
   package Fixtures renames Project_Tools.Test_Fixtures;
   use type Awk_CLI.Compatibility.Compatibility_Status;

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk compatibility");
   end Name;

   procedure Test_Compatibility_Registry (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Docs        : constant String := Fixtures.Read_Text_File ("../docs/compatibility.md");
      Conformance : constant String := Fixtures.Read_Text_File ("conformance/manifest/cases.txt");

      procedure Require_Reviewed (Id : String) is
      begin
         Assert (Awk_CLI.Compatibility.Has_Id (Id),
                 "registry contains reviewed entry " & Id);
         Assert (Project_Tools.Text.Contains (Docs, Id), "compatibility docs contain " & Id);
      end Require_Reviewed;
   begin
      Assert (Awk_CLI.Compatibility.Count = 7, "registry has reviewed compatibility entries");
      for Index in 1 .. Awk_CLI.Compatibility.Count loop
         Assert (Awk_CLI.Compatibility.Id (Index) /= "",
                 "registry entry has stable ID");
         Assert (Awk_CLI.Compatibility.Status (Index) = Awk_CLI.Compatibility.Supported,
                 "reviewed compatibility entry is supported by resolved awklib");
         Assert (Awk_CLI.Compatibility.Description (Index) /= "",
                 "registry entry has description");
         Assert (Awk_CLI.Compatibility.Source (Index) /= "",
                 "registry entry has limitation source or capability source");
         Assert (Awk_CLI.Compatibility.Documentation (Index) = "docs/compatibility.md",
                 "registry entry has documentation reference");
         Assert (Awk_CLI.Compatibility.Test_Reference (Index) /= "",
                 "registry entry has test reference");
      end loop;
      Require_Reviewed ("AWK-COMPAT-REGEX-001");
      Require_Reviewed ("AWK-COMPAT-GETLINE-001");
      Require_Reviewed ("AWK-COMPAT-GETLINE-002");
      Require_Reviewed ("AWK-COMPAT-UTF8-001");
      Require_Reviewed ("AWK-COMPAT-PRINTF-001");
      Require_Reviewed ("AWK-COMPAT-ASSIGNMENT-001");
      Require_Reviewed ("AWK-COMPAT-REDIRECTION-001");
      Assert
        (Project_Tools.Text.Contains (Docs, "No current entries are classified as unsupported"),
         "compatibility docs state the active limitation position");
      Assert
        (Project_Tools.Text.Contains (Conformance, "AWK-CONF-GETLINE-001|Supported"),
         "conformance manifest marks command getline supported");
   end Test_Compatibility_Registry;

   procedure Test_Conformance_Manifest (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Manifest : constant String := Fixtures.Read_Text_File ("conformance/manifest/cases.txt");

      procedure Require_Case
        (Id        : String;
         Status    : String;
         Case_File : String;
         Expected  : String;
         Reference : String)
      is
         Line : constant String :=
           Id & "|" & Status & "|" & Case_File & "|" & Expected & "|" & Reference;
      begin
         Assert (Project_Tools.Text.Contains (Manifest, Line), "manifest contains " & Id);
         Assert (Project_Tools.Files.File_Exists ("conformance/" & Case_File),
                 "case file exists for " & Id);
         Assert (Project_Tools.Files.File_Exists ("conformance/" & Expected),
                 "expected file exists for " & Id);
         Assert (Fixtures.Read_Text_File ("conformance/" & Case_File) /= "",
                 "case file is non-empty for " & Id);
         Assert (Fixtures.Read_Text_File ("conformance/" & Expected) /= "",
                 "expected file is non-empty for " & Id);
      end Require_Case;
   begin
      Require_Case
        ("AWK-CONF-PRINT-001", "Supported", "cases/print_record.awk",
         "expected/print_record.txt", "basic print through awklib");
      Require_Case
        ("AWK-CONF-FIELDS-001", "Supported", "cases/print_first_field.awk",
         "expected/print_first_field.txt", "field processing through awklib");
      Require_Case
        ("AWK-CONF-ASSIGNMENT-001", "Supported",
         "cases/runtime_assignment.awk", "expected/runtime_assignment.txt",
         "positional runtime assignment supported");
      Require_Case
        ("AWK-CONF-REDIRECTION-001", "Supported",
         "cases/append_redirection.awk", "expected/append_redirection.txt",
         "append redirection supported through awklib streaming callbacks");
      Require_Case
        ("AWK-CONF-GETLINE-001", "Supported",
         "cases/command_getline.awk", "expected/command_getline.txt",
         "command getline supported through awklib callback");
   end Test_Conformance_Manifest;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Compatibility_Registry'Access,
         "compatibility registry");
      Registration.Register_Routine
        (T, Test_Conformance_Manifest'Access,
         "conformance manifest");
   end Register_Tests;
end Awk_Tests.Compatibility;
