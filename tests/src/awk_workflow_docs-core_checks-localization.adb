with Project_Tools.Files;

package body Awk_Workflow_Docs.Core_Checks.Localization is
   package Files renames Project_Tools.Files;

   procedure Run is
   begin
      Files.Require_Contains
        ("../docs/localization.md", "awk.internal.localization_failed",
         "localization docs must document catalog-backed render fallback",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization.md", "last-resort containment",
         "localization docs must document catalog-backed render fallback",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization.md", "English fallback help and diagnostic",
         "localization docs must document help and diagnostic fallback checks",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization.md", "localized CLI text",
         "localization docs must document help and diagnostic fallback checks",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization.md", "Localization Reference",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "POSIX `awk` utility text",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "GNU awk",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "BWK awk",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "BusyBox awk",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "Reference run record",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "/usr/bin/mawk -W help",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "/usr/bin/busybox awk --help",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "Reference comparison checklist",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "Machine-checked reference cues",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization.md", "supported European state-language locale set",
         "localization docs must document supported European locale catalog validation",
         Quiet => True);
      Files.Require_Contains
        ("../docs/testing.md",
         "every supported European" & ASCII.LF & "state-language locale",
         "localization docs must document supported European locale catalog validation",
         Quiet => True);
   end Run;
end Awk_Workflow_Docs.Core_Checks.Localization;
