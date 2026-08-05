with AUnit.Assertions;

with Project_Tools.Text;

with Awk_Catalog_Policy;
with Awk_CLI;
with Awk_CLI.Testing;

package body Awk_Tests.Localization.Rendering_Cases.Help_Cases is
   use AUnit.Assertions;
   package Harness renames Awk_CLI.Testing;

   use type Awk_CLI.Exit_Code;

   procedure Test_All_Supported_Locales_Render_Help
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Escape : constant String := [1 => Character'Val (27)];

      procedure Require_Token (Output, Locale, Token : String) is
      begin
         Assert (Project_Tools.Text.Contains (Output, Token), Locale & " help contains " & Token);
      end Require_Token;
   begin
      for Index in 1 .. Awk_Catalog_Policy.Supported_Locale_Count loop
         declare
            Locale  : constant String := Awk_Catalog_Policy.Supported_Locale (Index);
            Context : Awk_CLI.Invocation_Context;
            Status  : Awk_CLI.Exit_Code;
         begin
            Harness.Add_Argument (Context, "--color=never");
            Harness.Add_Argument (Context, "--help");
            Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
            Harness.Set_Locale (Context, Locale);
            Status := Awk_CLI.Run (Context);
            declare
               Output : constant String := Harness.Standard_Output (Context);
            begin
               Assert (Status = 0, Locale & " help status");
               Assert (Harness.Standard_Error (Context) = "",
                       Locale & " help writes no standard error");
               Require_Token (Output, Locale, "awk");
               Require_Token (Output, Locale, "-F");
               Require_Token (Output, Locale, "-v");
               Require_Token (Output, Locale, "-f");
               Require_Token (Output, Locale, "--help");
               Require_Token (Output, Locale, "--version");
               Require_Token (Output, Locale, "--color=auto|always|never");
               Require_Token (Output, Locale, "BEGIN");
               Require_Token (Output, Locale, "getline");
               Require_Token (Output, Locale, "POSIX");
               Assert (not Project_Tools.Text.Contains (Output, "awk.help."),
                       Locale & " help does not expose raw help keys");
               Assert (not Project_Tools.Text.Contains (Output, "localization_failed"),
                       Locale & " help does not use localization failure fallback");
               Assert (not Project_Tools.Text.Contains (Output, Escape),
                       Locale & " color=never help emits no raw escape character");
            end;
         end;
      end loop;
   end Test_All_Supported_Locales_Render_Help;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_All_Supported_Locales_Render_Help'Access,
         "all supported locale help renders");
   end Register;

end Awk_Tests.Localization.Rendering_Cases.Help_Cases;
