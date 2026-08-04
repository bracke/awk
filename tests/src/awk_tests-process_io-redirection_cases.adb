with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Files;
with Project_Tools.Text;

package body Awk_Tests.Process_IO.Redirection_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Redirection (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Target : constant String := "tests/fixtures/filesystem/process_redir.txt";
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("--color=always"),
            Argument ("BEGIN { print ""saved"" > """ & Target & """ }")]);
   begin
      Ensure_Filesystem_Fixture_Directory;
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
      Project_Tools.Files.Write_Raw_File ("../" & Target, "old" & LF & "content" & LF);

      declare
         Result : constant Captured_Process := Run_Awk ("awk process redirection", Args);
      begin
         Assert (Result.Status = 0, "process redirection exits successfully");
         Assert (Output_String (Result) = "", "process redirected output not on stdout");
      end;

      Assert (Read_Text_File ("../" & Target) = "saved", "process redirection file content");
      Assert (not Project_Tools.Text.Contains (Read_Text_File ("../" & Target), "old"),
              "overwrite redirection replaces existing file content");
      Assert (not Project_Tools.Text.Contains
                (Read_Text_File ("../" & Target), Character'Val (27) & "["),
              "color=always does not style redirected output");

      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Redirection;

   procedure Test_Process_Append_Redirection (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Target : constant String := "tests/fixtures/filesystem/process_append.txt";
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("--color=always"),
            Argument
              ("BEGIN { print ""first"" >> """ & Target
               & """; print ""second"" >> """ & Target & """ }")]);
   begin
      Ensure_Filesystem_Fixture_Directory;
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
      Project_Tools.Files.Write_Raw_File ("../" & Target, "existing" & LF);

      declare
         Result : constant Captured_Process := Run_Awk ("awk process append redirection", Args);
      begin
         Assert (Result.Status = 0, "process append redirection exits successfully");
         Assert (Output_String (Result) = "", "process append redirection not on stdout");
      end;

      Assert
        (Project_Tools.Text.Contains (Read_Text_File ("../" & Target), "existing") and then
         Project_Tools.Text.Contains (Read_Text_File ("../" & Target), "first" & LF & "second"),
         "append redirection preserves existing content and write order");
      Assert (Read_Text_File ("../" & Target) /= "first" & LF & "second",
              "append redirection does not replace existing file content");
      Assert (not Project_Tools.Text.Contains
                (Read_Text_File ("../" & Target), Character'Val (27) & "["),
              "color=always does not style appended redirected output");

      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Append_Redirection;

   procedure Test_Process_Redirection_Target_Directory_Failure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Target : constant String := "tests/fixtures/filesystem";

      procedure Expect_Failure (Operator, Message : String) is
         Args : constant Process_Arguments :=
           Arguments
             ([Argument
                 ("BEGIN { print ""x"" " & Operator
                  & " """ & Target & """; print ""after"" }")]);
      begin
         declare
            Result : constant Captured_Process := Run_Awk_Err_To_Out (Args);
            Output : constant String := Output_String (Result);
         begin
            Assert (Result.Status = 3, Message & " exits with host I/O status");
            Assert (Project_Tools.Text.Contains
                      (Output,
                       English_Error_Header
                         (English_Text
                            ("awk.output_file.write_failed", "path", Target))),
                    Message & " reports the redirected output target");
            Assert (not Project_Tools.Text.Contains (Output, "after"),
                    Message & " does not continue after required output failure");
            Assert (not Project_Tools.Text.Contains (Output, Character'Val (27) & "["),
                    Message & " diagnostic is unstyled by default capture");
         end;
      end Expect_Failure;
   begin
      Ensure_Filesystem_Fixture_Directory;
      Expect_Failure (">", "overwrite redirection to directory");
      Expect_Failure (">>", "append redirection to directory");
   end Test_Process_Redirection_Target_Directory_Failure;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Process_Redirection'Access, "process redirection");
      Registration.Register_Routine
        (T, Test_Process_Append_Redirection'Access, "process append redirection");
      Registration.Register_Routine
        (T, Test_Process_Redirection_Target_Directory_Failure'Access,
         "process redirection target directory failure");
   end Register;
end Awk_Tests.Process_IO.Redirection_Cases;
