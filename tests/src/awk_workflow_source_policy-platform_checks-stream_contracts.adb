with Project_Tools.Files;

package body Awk_Workflow_Source_Policy.Platform_Checks.Stream_Contracts is
   package Files renames Project_Tools.Files;

   procedure Run is
   begin
      Files.Require_Contains
        ("../src/library/awk_cli-platform-standard_streams.adb",
         "while Remaining > 0 loop",
         "standard stream writes must retry partial writes",
         Quiet => False);
      Files.Require_Contains
        ("../src/library/awk_cli-platform-standard_streams.adb",
         "Interfaces.C_Streams.set_binary_mode",
         "standard stream writes must preserve binary bytes",
         Quiet => False);
      Files.Require_Contains
        ("../src/library/awk_cli-platform-standard_streams.adb",
         "Interfaces.C_Streams.fflush",
         "standard stream writes must report flush failures",
         Quiet => False);
      Files.Require_Contains
        ("../docs/dependency-policy.md",
         "Hostkit stream helper boundary: local exact stream helpers remain in",
         "dependency policy must document the local stream-helper boundary",
         Quiet => False);
      Files.Require_Contains
        ("../docs/ai/package-contracts.md",
         "Local byte-buffer and exact standard-stream helpers are allowed only inside",
         "package contracts must document the local stream-helper boundary",
         Quiet => False);
   end Run;
end Awk_Workflow_Source_Policy.Platform_Checks.Stream_Contracts;
