with Project_Tools.Files;

package body Awk_Workflow_Docs.Workflow_Checks.Release_Docs is
   package Files renames Project_Tools.Files;

   procedure Run is
   begin
      Files.Require_Contains
        ("../docs/releasing.md", "--release --profiles=*=release",
         "release docs must document release-profile builds", Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "clean git working tree",
         "release docs must document clean-tree enforcement", Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "local Alire workspace pins",
         "release docs must mention workspace pin verification", Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "FNV-1a-64",
         "release docs must document manifest checksum algorithm", Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "dependency policy",
         "release docs must document packaged audit documentation", Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "traceability matrix",
         "release docs must document packaged audit documentation", Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md",
         "`terminal_styles = ""=0.1.0-dev""` and `hostkit = ""=0.1.0-dev""`",
         "release traceability docs must mention current dev dependency constraints",
         Quiet => True);
      Files.Require_Contains
        ("../docs/ai/traceability.md",
         "`terminal_styles = ""=0.1.0-dev""` and" & ASCII.LF &
         "`hostkit = ""=0.1.0-dev""`",
         "release traceability docs must mention current dev dependency constraints",
         Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "temporary prefix",
         "release docs must document temporary install-prefix validation",
         Quiet => True);
      Files.Require_Contains
        ("../docs/dependency-policy.md", "workspace release model",
         "dependency policy must document workspace release model", Quiet => True);
      Files.Require_Contains
        ("../docs/dependency-policy.md",
         "No direct dependency may use an unrestricted wildcard",
         "dependency policy must reject wildcard release constraints",
         Quiet => True);
      Files.Require_Contains
        ("../docs/dependency-policy.md", "Publish readiness is a separate gate",
         "dependency policy must document publish readiness separation",
         Quiet => True);
   end Run;
end Awk_Workflow_Docs.Workflow_Checks.Release_Docs;
