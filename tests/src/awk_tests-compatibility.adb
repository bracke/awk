with AUnit.Assertions;

with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Awk_CLI.Compatibility;

package body Awk_Tests.Compatibility is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;

   LF : constant String := [1 => ASCII.LF];

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk compatibility");
   end Name;

   function File_Text (Path : String) return String is
      File   : Ada.Text_IO.File_Type;
      Result : U.Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         U.Append (Result, Ada.Text_IO.Get_Line (File));
         if not Ada.Text_IO.End_Of_File (File) then
            U.Append (Result, LF);
         end if;
      end loop;
      Ada.Text_IO.Close (File);
      return U.To_String (Result);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return "";
   end File_Text;

   function Contains (Text, Pattern : String) return Boolean is
   begin
      if Pattern'Length = 0 then
         return True;
      end if;
      if Text'Length < Pattern'Length then
         return False;
      end if;
      for Index in Text'First .. Text'Last - Pattern'Length + 1 loop
         if Text (Index .. Index + Pattern'Length - 1) = Pattern then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   procedure Test_Compatibility_Registry (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Docs        : constant String := File_Text ("../docs/compatibility.md");
      Conformance : constant String := File_Text ("conformance/manifest/cases.txt");
   begin
      Assert (Awk_CLI.Compatibility.Count = 0, "registry has no active limitation entries");
      Assert (not Awk_CLI.Compatibility.Has_Id ("AWK-COMPAT-GETLINE-001"),
              "main-input getline from BEGIN is no longer a compatibility limitation");
      Assert (not Awk_CLI.Compatibility.Has_Id ("AWK-COMPAT-GETLINE-002"),
              "command getline is no longer a compatibility limitation");
      Assert (not Awk_CLI.Compatibility.Has_Id ("AWK-COMPAT-UTF8-001"),
              "malformed UTF-8 is no longer a compatibility limitation");
      Assert (not Awk_CLI.Compatibility.Has_Id ("AWK-COMPAT-PRINTF-001"),
              "printf %c field width is no longer a compatibility limitation");
      Assert
        (Contains (Docs, "No current compatibility-registry entries are active"),
         "compatibility docs state the empty registry");
      Assert
        (Contains (Conformance, "AWK-CONF-GETLINE-001|Supported"),
         "conformance manifest marks command getline supported");
   end Test_Compatibility_Registry;

   procedure Test_Conformance_Manifest (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Manifest : constant String := File_Text ("conformance/manifest/cases.txt");

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
         Assert (Contains (Manifest, Line), "manifest contains " & Id);
         Assert (Ada.Directories.Exists ("conformance/" & Case_File),
                 "case file exists for " & Id);
         Assert (Ada.Directories.Exists ("conformance/" & Expected),
                 "expected file exists for " & Id);
         Assert (File_Text ("conformance/" & Case_File) /= "",
                 "case file is non-empty for " & Id);
         Assert (File_Text ("conformance/" & Expected) /= "",
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
