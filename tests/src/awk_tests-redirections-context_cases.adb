with AUnit.Assertions;

with Awk_CLI;
with Awk_CLI.Execution;
with Awk_CLI.Testing;

package body Awk_Tests.Redirections.Context_Cases is
   use AUnit.Assertions;
   package Harness renames Awk_CLI.Testing;

   LF : constant String := [1 => ASCII.LF];

   use type Awk_CLI.Exit_Code;

   procedure Test_Context_Redirection (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "BEGIN { print ""saved"" > ""out.txt"" }");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "redirection run succeeds");
      Assert (Harness.Written_File_Count (Context) = 1, "one redirected file written");
      Assert (Harness.Written_File_Name (Context, 1) = "out.txt", "redirection target");
      Assert (Harness.Written_File_Content (Context, 1) = "saved" & LF, "redirection content");
      Assert (not Harness.Written_File_Append (Context, 1), "overwrite redirection is recorded");
      Assert (Harness.Standard_Output (Context) = "", "redirected output not sent to stdout");
   end Test_Context_Redirection;

   procedure Test_Context_Multiple_Redirections
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument
        (Context,
         "BEGIN { print ""a1"" > ""a.txt""; print ""b1"" > ""b.txt""; print ""a2"" > ""a.txt"" }");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "multiple redirections succeed");
      Assert (Harness.Written_File_Count (Context) = 3,
              "awklib exposes live redirected writes");
      Assert (Harness.Written_File_Name (Context, 1) = "a.txt",
              "first redirection target is materialized first");
      Assert (Harness.Written_File_Content (Context, 1) = "a1" & LF,
              "first same-target write is exact");
      Assert (Harness.Written_File_Name (Context, 2) = "b.txt",
              "second redirection target is materialized second");
      Assert (Harness.Written_File_Content (Context, 2) = "b1" & LF,
              "second target content is exact");
      Assert (Harness.Written_File_Name (Context, 3) = "a.txt",
              "third write returns to first target");
      Assert (Harness.Written_File_Content (Context, 3) = "a2" & LF,
              "third write content is exact");
      Assert (Harness.Written_File_Append (Context, 3),
              "later writes to an open target append");
   end Test_Context_Multiple_Redirections;

   procedure Test_Context_Append_Redirection (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "BEGIN { print ""saved"" >> ""out.txt"" }");
      Harness.Add_File (Context, "out.txt", "old" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "append redirection run succeeds");
      Assert (Harness.Written_File_Count (Context) = 1, "one captured write recorded");
      Assert (Harness.Written_File_Name (Context, 1) = "out.txt", "redirection target");
      Assert (Harness.Written_File_Content (Context, 1) = "saved" & LF, "write content");
      Assert (Awk_CLI.Execution.Supports_Redirection_Append_Mode,
              "execution adapter exposes append-mode capability");
      Assert (Harness.Written_File_Append (Context, 1),
              "awklib streaming redirection exposes append intent");
      Assert (Harness.Written_File_Content (Context, 1) = "saved" & LF,
              "append write content is exact");
   end Test_Context_Append_Redirection;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Context_Redirection'Access, "context redirection");
      Registration.Register_Routine
        (T, Test_Context_Multiple_Redirections'Access,
         "context multiple redirections");
      Registration.Register_Routine
        (T, Test_Context_Append_Redirection'Access,
         "context append redirection");
   end Register;

end Awk_Tests.Redirections.Context_Cases;
