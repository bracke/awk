with AUnit.Assertions;

with Ada.Strings.Fixed;

with Project_Tools.Test_Fixtures;
with Project_Tools.Text;

with Awk_Catalog_Policy;
with Awk_CLI;
with Awk_CLI.Testing;

package body Awk_Tests.Localization.Rendering_Cases.Diagnostic_Cases.All_Locale_Cases is
   use AUnit.Assertions;
   package Fixtures renames Project_Tools.Test_Fixtures;
   package Harness renames Awk_CLI.Testing;

   LF : constant String := [1 => ASCII.LF];

   use type Awk_CLI.Exit_Code;

   procedure Test_All_Supported_Locales_Render_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Catalog : constant String := Fixtures.Read_Text_File ("../resources/messages/catalog.txt");
      Escape  : constant String := [1 => Character'Val (27)];

      function Catalog_Value (Key : String) return String is
         Prefix : constant String := Key & " = ";
         Start  : constant Natural := Ada.Strings.Fixed.Index (Catalog, Prefix);
         Stop   : Natural;
      begin
         Assert (Start /= 0, "catalog contains " & Key);
         Stop := Ada.Strings.Fixed.Index
           (Catalog (Start + Prefix'Length .. Catalog'Last), LF);
         if Stop = 0 then
            return Catalog (Start + Prefix'Length .. Catalog'Last);
         end if;
         return Catalog (Start + Prefix'Length .. Stop - 1);
      end Catalog_Value;

      function Before_Option (Text : String) return String is
         Mark : constant Natural := Ada.Strings.Fixed.Index (Text, "{option}");
      begin
         if Mark <= Text'First then
            return "";
         end if;
         return Text (Text'First .. Mark - 1);
      end Before_Option;
   begin
      for Index in 1 .. Awk_Catalog_Policy.Supported_Locale_Count loop
         declare
            Locale  : constant String := Awk_Catalog_Policy.Supported_Locale (Index);
            Context : Awk_CLI.Invocation_Context;
            Status  : Awk_CLI.Exit_Code;
            Prefix  : constant String :=
              Before_Option (Catalog_Value (Locale & ".awk.usage.unknown_option"));
         begin
            Harness.Add_Argument (Context, "--bad");
            Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
            Harness.Set_Locale (Context, Locale);
            Status := Awk_CLI.Run (Context);
            Assert (Status = 2, Locale & " usage diagnostic status");
            Assert
              (Prefix = ""
               or else Project_Tools.Text.Contains
                 (Harness.Standard_Error (Context), Prefix),
               Locale & " diagnostic renders localized catalog prefix");
            Assert (Project_Tools.Text.Contains (Harness.Standard_Error (Context), "--bad"),
                    Locale & " diagnostic interpolates option argument");
            Assert
              (not Project_Tools.Text.Contains
                 (Harness.Standard_Error (Context), "awk.usage.unknown_option"),
               Locale & " diagnostic does not expose raw message key");
            Assert
              (not Project_Tools.Text.Contains
                 (Harness.Standard_Error (Context), "localization_failed"),
               Locale & " diagnostic does not use localization failure fallback");
            Assert
              (not Project_Tools.Text.Contains (Harness.Standard_Error (Context), Escape),
               Locale & " diagnostic emits no raw escape character");
         end;
      end loop;
   end Test_All_Supported_Locales_Render_Diagnostics;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_All_Supported_Locales_Render_Diagnostics'Access,
         "all supported locale diagnostics render");
   end Register;
end Awk_Tests.Localization.Rendering_Cases.Diagnostic_Cases.All_Locale_Cases;
