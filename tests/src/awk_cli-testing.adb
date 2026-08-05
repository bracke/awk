package body Awk_CLI.Testing is
   package Context_State renames Awk_CLI_Context_State;

   procedure Add_Argument (Context : in out Invocation_Context; Value : String) is
   begin
      Context.Config.Arguments.Append (U.To_Unbounded_String (Value));
   end Add_Argument;

   procedure Set_Standard_Input (Context : in out Invocation_Context; Value : String) is
   begin
      Context.IO.Standard_In := U.To_Unbounded_String (Value);
   end Set_Standard_Input;

   procedure Set_Locale (Context : in out Invocation_Context; Value : String) is
   begin
      Context.Config.Locale := U.To_Unbounded_String (Value);
   end Set_Locale;

   procedure Set_Catalog_Path (Context : in out Invocation_Context; Value : String) is
   begin
      Context.Config.Catalog_Path := U.To_Unbounded_String (Value);
   end Set_Catalog_Path;

   procedure Add_File
     (Context  : in out Invocation_Context;
      Path     : String;
      Content  : String;
      Readable : Boolean := True;
      Writable : Boolean := True;
      Openable : Boolean := True) is
   begin
      Context.IO.Files.Append
        (Context_State.Virtual_File'
           (Path     => U.To_Unbounded_String (Path),
            Content  => U.To_Unbounded_String (Content),
            Readable => Readable,
            Writable => Writable,
            Openable => Openable));
   end Add_File;

   procedure Add_Command_Output
     (Context : in out Invocation_Context;
      Command : String;
      Output  : String) is
   begin
      Context.IO.Commands.Append
        (Context_State.Command_Output'
           (Command => U.To_Unbounded_String (Command),
            Output  => U.To_Unbounded_String (Output)));
   end Add_Command_Output;

   procedure Add_Environment
     (Context : in out Invocation_Context;
      Name    : String;
      Value   : String) is
   begin
      Context.IO.Environment.Append
        (Context_State.Env_Item'(Name => U.To_Unbounded_String (Name),
                                 Value => U.To_Unbounded_String (Value)));
   end Add_Environment;

   procedure Fail_Standard_Output (Context : in out Invocation_Context; Enabled : Boolean) is
   begin
      Context.IO.Stdout_Fails := Enabled;
   end Fail_Standard_Output;

   procedure Fail_Standard_Error (Context : in out Invocation_Context; Enabled : Boolean) is
   begin
      Context.IO.Stderr_Fails := Enabled;
   end Fail_Standard_Error;

   procedure Fail_Standard_Input (Context : in out Invocation_Context; Enabled : Boolean) is
   begin
      Context.IO.Stdin_Fails := Enabled;
   end Fail_Standard_Input;

   procedure Set_Standard_Output_Terminal
     (Context : in out Invocation_Context;
      Enabled : Boolean) is
   begin
      Context.Config.Stdout_Terminal := Enabled;
   end Set_Standard_Output_Terminal;

   procedure Set_Standard_Error_Terminal
     (Context : in out Invocation_Context;
      Enabled : Boolean) is
   begin
      Context.Config.Stderr_Terminal := Enabled;
   end Set_Standard_Error_Terminal;

   procedure Set_No_Color (Context : in out Invocation_Context; Enabled : Boolean) is
   begin
      Context.Config.No_Color := Enabled;
   end Set_No_Color;

   function Standard_Output (Context : Invocation_Context) return String is
     (U.To_String (Context.IO.Standard_Out));

   function Standard_Error (Context : Invocation_Context) return String is
     (U.To_String (Context.IO.Standard_Err));

   function Has_Diagnostic (Context : Invocation_Context) return Boolean is
     (Context.Last_Diagnostic.Set);

   function Last_Diagnostic_Message_Id (Context : Invocation_Context) return String is
     (U.To_String (Context.Last_Diagnostic.Id));

   function Last_Diagnostic_Category (Context : Invocation_Context) return String is
     (U.To_String (Context.Last_Diagnostic.Category));

   function Last_Diagnostic_Severity (Context : Invocation_Context) return String is
     (U.To_String (Context.Last_Diagnostic.Severity));

   function Written_File_Count (Context : Invocation_Context) return Natural is
     (Natural (Context.IO.Writes.Length));

   function Written_File_Name
     (Context : Invocation_Context;
      Index   : Positive) return String is
     (U.To_String (Context.IO.Writes.Element (Index).Path));

   function Written_File_Content
     (Context : Invocation_Context;
      Index   : Positive) return String is
     (U.To_String (Context.IO.Writes.Element (Index).Content));

   function Written_File_Append
     (Context : Invocation_Context;
      Index   : Positive) return Boolean is
     (Context.IO.Writes.Element (Index).Append);
end Awk_CLI.Testing;
