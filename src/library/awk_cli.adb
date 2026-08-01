with Ada.Strings.Unbounded;
with Awk_CLI.Diagnostics;
with Awk_CLI.Environment;
with Awk_CLI.Execution;
with Awk_CLI.Inputs;
with Awk_CLI.Localization;
with Awk_CLI.Operands;
with Awk_CLI.Options;
with Awk_CLI.Output;
with Awk_CLI.Platform;
with Awk_CLI.Programs;
with Awk_CLI.Redirections;

package body Awk_CLI is
   package D renames Awk_CLI.Diagnostics;
   package U renames Ada.Strings.Unbounded;

   procedure Initialize_From_Process (Context : in out Invocation_Context) is
      pragma Unreferenced (Context);
   begin
      null;
   end Initialize_From_Process;

   function Run (Context : in out Invocation_Context) return Exit_Code is
      pragma Unreferenced (Context);
      Catalog : Awk_CLI.Localization.Catalog;

      function Emit_Diagnostic (Item : D.Diagnostic) return Exit_Code is
      begin
         if not Awk_CLI.Platform.Write_Standard_Error
           (Awk_CLI.Output.Diagnostic_Text (Catalog, Item))
         then
            return Exit_Code (D.IO_Exit);
         end if;
         return Exit_Code (D.Status_For (Item));
      end Emit_Diagnostic;

      Parsed : constant Awk_CLI.Options.Parse_Result :=
        Awk_CLI.Options.Parse (Awk_CLI.Platform.Process_Arguments);
   begin
      Awk_CLI.Localization.Initialize
        (Catalog, Awk_CLI.Platform.Catalog_Path, Awk_CLI.Platform.Locale);

      if not Parsed.Ok then
         return Emit_Diagnostic (Parsed.Diagnostic);
      end if;

      Awk_CLI.Output.Set_Color (Parsed.Options.Color);

      if Parsed.Options.Help_Requested then
         if Awk_CLI.Platform.Write_Standard_Output (Awk_CLI.Output.Help (Catalog)) then
            return Exit_Code (D.Success_Exit);
         else
            return Exit_Code (D.IO_Exit);
         end if;
      elsif Parsed.Options.Version_Requested then
         if Awk_CLI.Platform.Write_Standard_Output (Awk_CLI.Output.Version (Catalog)) then
            return Exit_Code (D.Success_Exit);
         else
            return Exit_Code (D.IO_Exit);
         end if;
      end if;

      declare
         Source_Result : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve (Parsed.Options, Awk_CLI.Platform.Read_File'Access);
      begin
         if not Source_Result.Ok then
            return Emit_Diagnostic (Source_Result.Diagnostic);
         end if;

         declare
            Classified : constant Awk_CLI.Operands.Operand_Vectors.Vector :=
              Awk_CLI.Operands.Classify (Source_Result.Source.Operands);
            Input_Result : constant Awk_CLI.Inputs.Load_Result :=
              Awk_CLI.Inputs.Load
                (Classified, U.To_String (Awk_CLI.Platform.Read_Standard_Input),
                 Awk_CLI.Platform.Read_File'Access);
         begin
            if not Input_Result.Ok then
               return Emit_Diagnostic (Input_Result.Diagnostic);
            end if;

            declare
               Exec_Result : constant Awk_CLI.Execution.Execution_Result :=
                 Awk_CLI.Execution.Execute
                   (U.To_String (Source_Result.Source.Text),
                    Parsed.Options, Classified, Input_Result.Files, Awk_CLI.Environment.Collect);
            begin
               if not Exec_Result.Ok then
                  return Emit_Diagnostic (Exec_Result.Diagnostic);
               end if;

               declare
                  Redir_Result : constant Awk_CLI.Redirections.Materialize_Result :=
                    Awk_CLI.Redirections.Materialize
                      (Exec_Result.Redirections, Awk_CLI.Platform.Write_File'Access);
               begin
                  if not Redir_Result.Ok then
                     return Emit_Diagnostic (Redir_Result.Diagnostic);
                  end if;
               end;

               if not Awk_CLI.Platform.Write_Standard_Output
                 (U.To_String (Exec_Result.Standard_Output))
               then
                  return Emit_Diagnostic
                    (D.Make ("awk.standard_output.write_failed", D.Error, D.Output));
               end if;

               if Exec_Result.Exit_Status < 0 or else Exec_Result.Exit_Status > 255 then
                  return Exit_Code (D.Interpreter_Exit);
               else
                  return Exit_Code (Exec_Result.Exit_Status);
               end if;
            end;
         end;
      end;
   exception
      when others =>
         return Exit_Code (D.Internal_Exit);
   end Run;
end Awk_CLI;
