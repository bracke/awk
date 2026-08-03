with Awk_CLI.Context_IO;
with Awk_CLI.Diagnostics;
with Awk_CLI.Invocation;
with Awk_CLI.Localization;
with Awk_CLI.Options;
with Awk_CLI.Output;
with Awk_CLI.Platform;

package body Awk_CLI is
   package D renames Awk_CLI.Diagnostics;

   procedure Clear (Context : in out Invocation_Context) is
   begin
      Context.Arguments.Clear;
      Context.Standard_In := U.Null_Unbounded_String;
      Context.Locale := U.To_Unbounded_String ("en");
      Context.Catalog_Path := U.To_Unbounded_String ("resources/messages/catalog.txt");
      Context.Files.Clear;
      Context.Commands.Clear;
      Context.Environment.Clear;
      Context.Standard_Out := U.Null_Unbounded_String;
      Context.Standard_Err := U.Null_Unbounded_String;
      Context.Diagnostic_Set := False;
      Context.Diagnostic_Id := U.Null_Unbounded_String;
      Context.Diagnostic_Category := U.Null_Unbounded_String;
      Context.Diagnostic_Severity := U.Null_Unbounded_String;
      Context.Writes.Clear;
      Context.Use_Process := False;
      Context.Stdin_Fails := False;
      Context.Stdout_Fails := False;
      Context.Stderr_Fails := False;
      Context.Stdout_Terminal := False;
      Context.Stderr_Terminal := False;
      Context.No_Color := False;
   end Clear;

   procedure Initialize_From_Process (Context : in out Invocation_Context) is
   begin
      Clear (Context);
      for Argument of Awk_CLI.Platform.Process_Arguments loop
         Context.Arguments.Append (Argument);
      end loop;
      Context.Locale := U.To_Unbounded_String (Awk_CLI.Platform.Locale);
      Context.Catalog_Path := U.To_Unbounded_String (Awk_CLI.Platform.Catalog_Path);
      Context.Use_Process := True;
      Context.Stdout_Terminal := Awk_CLI.Platform.Standard_Output_Is_Terminal;
      Context.Stderr_Terminal := Awk_CLI.Platform.Standard_Error_Is_Terminal;
      Context.No_Color := Awk_CLI.Platform.No_Color_Active;
   end Initialize_From_Process;

   function Run (Context : in out Invocation_Context) return Exit_Code is
      Catalog : Awk_CLI.Localization.Catalog;

      function Parsed_Arguments return Awk_CLI.Options.String_Vectors.Vector is
         Result : Awk_CLI.Options.String_Vectors.Vector;
      begin
         for Argument of Context.Arguments loop
            Result.Append (Argument);
         end loop;
         return Result;
      end Parsed_Arguments;

      function Emit_Diagnostic (Item : D.Diagnostic) return Exit_Code is
      begin
         Context.Diagnostic_Set := True;
         Context.Diagnostic_Id := Item.Message_Id;
         Context.Diagnostic_Category := U.To_Unbounded_String (D.Diagnostic_Category'Image (Item.Category));
         Context.Diagnostic_Severity := U.To_Unbounded_String (D.Diagnostic_Severity'Image (Item.Severity));
         if not Awk_CLI.Context_IO.Write_Standard_Error
           (Context,
            Awk_CLI.Output.Diagnostic_Text
              (Catalog, Item, Context.Stderr_Terminal, Context.No_Color))
         then
            return Exit_Code (D.IO_Exit);
         end if;
         return Exit_Code (D.Status_For (Item));
      end Emit_Diagnostic;

      function Emit_Internal_Diagnostic return Exit_Code is
         Item : constant D.Diagnostic :=
           D.Make
             ("awk.internal.unexpected_exception",
              D.Internal_Error,
              D.Internal);
      begin
         Context.Diagnostic_Set := True;
         Context.Diagnostic_Id := Item.Message_Id;
         Context.Diagnostic_Category := U.To_Unbounded_String (D.Diagnostic_Category'Image (Item.Category));
         Context.Diagnostic_Severity := U.To_Unbounded_String (D.Diagnostic_Severity'Image (Item.Severity));
         if not Awk_CLI.Context_IO.Write_Standard_Error
           (Context,
            Awk_CLI.Output.Diagnostic_Text
              (Catalog, Item, Context.Stderr_Terminal, Context.No_Color))
         then
            return Exit_Code (D.Internal_Exit);
         end if;
         return Exit_Code (D.Internal_Exit);
      exception
         when others =>
            return Exit_Code (D.Internal_Exit);
      end Emit_Internal_Diagnostic;

      function Execute_Parsed
        (Parsed : Awk_CLI.Options.Parse_Result) return Exit_Code
      is
      begin
         if not Parsed.Ok then
            Awk_CLI.Output.Set_Color (Parsed.Color);
            return Emit_Diagnostic (Parsed.Diagnostic);
         end if;

         Awk_CLI.Output.Set_Color (Parsed.Options.Color);

         if Parsed.Options.Help_Requested then
            if Awk_CLI.Context_IO.Write_Standard_Output
              (Context, Awk_CLI.Output.Help
                 (Catalog, Context.Stdout_Terminal, Context.No_Color))
            then
               return Exit_Code (D.Success_Exit);
            else
               return Exit_Code (D.IO_Exit);
            end if;
         elsif Parsed.Options.Version_Requested then
            if Awk_CLI.Context_IO.Write_Standard_Output
              (Context, Awk_CLI.Output.Version (Catalog))
            then
               return Exit_Code (D.Success_Exit);
            else
               return Exit_Code (D.IO_Exit);
            end if;
         end if;

         declare
            Result : constant Awk_CLI.Invocation.Invocation_Result :=
              Awk_CLI.Invocation.Execute (Context, Parsed.Options);
         begin
            if Result.Ok then
               return Result.Exit_Status;
            else
               return Emit_Diagnostic (Result.Diagnostic);
            end if;
         end;
      exception
         when others =>
            return Emit_Internal_Diagnostic;
      end Execute_Parsed;
   begin
      Awk_CLI.Localization.Initialize
        (Catalog, U.To_String (Context.Catalog_Path), U.To_String (Context.Locale));

      return Execute_Parsed (Awk_CLI.Options.Parse (Parsed_Arguments));
   exception
      when others =>
         return Emit_Internal_Diagnostic;
   end Run;
end Awk_CLI;
