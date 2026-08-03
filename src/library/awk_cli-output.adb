with Awk_Config;
with Ada.Strings.Unbounded;
with Awk_CLI.Execution;
with Terminal_Styles;

package body Awk_CLI.Output is
   package L renames Awk_CLI.Localization;
   package D renames Awk_CLI.Diagnostics;

   function Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      if Raw'Length > 0 and then Raw (Raw'First) = ' ' then
         return Raw (Raw'First + 1 .. Raw'Last);
      else
         return Raw;
      end if;
   end Image;

   procedure Set_Color (Mode : Awk_CLI.Options.Color_Mode) is
   begin
      case Mode is
         when Awk_CLI.Options.Color_Auto =>
            Terminal_Styles.Set_Color_Policy (Terminal_Styles.Color_Auto);
         when Awk_CLI.Options.Color_Always =>
            Terminal_Styles.Set_Color_Policy (Terminal_Styles.Color_Always);
         when Awk_CLI.Options.Color_Never =>
            Terminal_Styles.Set_Color_Policy (Terminal_Styles.Color_Never);
      end case;
   end Set_Color;

   function Styled
     (Text : String;
      Role : Terminal_Styles.Style_Role;
      Destination_Is_Terminal : Boolean;
      No_Color_Active        : Boolean) return String
   is
      Policy : constant Terminal_Styles.Color_Policy :=
        Terminal_Styles.Current_Color_Policy;
   begin
      case Policy is
         when Terminal_Styles.Color_Never =>
            return Text;

         when Terminal_Styles.Color_Always =>
            return Terminal_Styles.Decorate (Text, Role);

         when Terminal_Styles.Color_Auto =>
            if (not Destination_Is_Terminal) or else No_Color_Active then
               return Text;
            end if;

            Terminal_Styles.Set_Color_Policy (Terminal_Styles.Color_Always);
            declare
               Result : constant String := Terminal_Styles.Decorate (Text, Role);
            begin
               Terminal_Styles.Set_Color_Policy (Policy);
               return Result;
            exception
               when others =>
                  Terminal_Styles.Set_Color_Policy (Policy);
                  raise;
            end;
      end case;
   end Styled;

   type Help_Line is record
      Key         : U.Unbounded_String;
      Is_Header   : Boolean := False;
      Blank_After : Natural := 0;
   end record;

   function Line
     (Key         : String;
      Is_Header   : Boolean := False;
      Blank_After : Natural := 0) return Help_Line is
     (Key         => U.To_Unbounded_String (Key),
      Is_Header   => Is_Header,
      Blank_After => Blank_After);

   Help_Lines : constant array (Positive range <>) of Help_Line :=
     [Line ("awk.help.title", Is_Header => True),
      Line ("awk.help.summary", Blank_After => 1),
      Line ("awk.help.usage.direct_program"),
      Line ("awk.help.usage.program_files", Blank_After => 1),
      Line ("awk.help.options.field_separator"),
      Line ("awk.help.options.variable"),
      Line ("awk.help.options.program_file"),
      Line ("awk.help.options.color"),
      Line ("awk.help.options.help"),
      Line ("awk.help.options.version"),
      Line ("awk.help.options.terminator", Blank_After => 1),
      Line ("awk.help.operands"),
      Line ("awk.help.stdin"),
      Line ("awk.help.exit_statuses", Blank_After => 1),
      Line ("awk.help.compatibility.heading", Is_Header => True),
      Line ("awk.help.compatibility.awklib_limitations")];

   procedure Append_Help_Line
     (Result                  : in out U.Unbounded_String;
      Catalog                 : L.Catalog;
      Item                    : Help_Line;
      Destination_Is_Terminal : Boolean;
      No_Color_Active         : Boolean)
   is
      LF   : constant String := [1 => ASCII.LF];
      Text : constant String := L.Text (Catalog, U.To_String (Item.Key));
   begin
      if Item.Is_Header then
         U.Append
           (Result,
            Styled
              (Text, Terminal_Styles.Role_Header, Destination_Is_Terminal, No_Color_Active));
      else
         U.Append (Result, Text);
      end if;

      U.Append (Result, LF);
      for Blank in 1 .. Item.Blank_After loop
         U.Append (Result, LF);
      end loop;
   end Append_Help_Line;

   function Help
     (Catalog : L.Catalog;
      Destination_Is_Terminal : Boolean;
      No_Color_Active        : Boolean := False) return String
   is
      Result : U.Unbounded_String;
   begin
      for Item of Help_Lines loop
         Append_Help_Line
           (Result, Catalog, Item, Destination_Is_Terminal, No_Color_Active);
      end loop;

      return U.To_String (Result);
   end Help;

   function Version (Catalog : L.Catalog) return String is
      LF : constant String := [1 => ASCII.LF];
   begin
      return
        L.Text (Catalog, "awk.version.program",
                "version", Awk_Config.Crate_Version) & LF &
        L.Text (Catalog, "awk.version.interpreter",
                "version", Awk_CLI.Execution.Interpreter_Version) & LF &
        L.Text (Catalog, "awk.version.license") & LF;
   end Version;

   function Source_Display_Name (Catalog : L.Catalog; Source_Name : String) return String is
   begin
      if Source_Name = "awk.source.command_line" then
         return L.Text (Catalog, Source_Name);
      else
         return Source_Name;
      end if;
   end Source_Display_Name;

   function Diagnostic_Text
     (Catalog : L.Catalog;
      Item    : D.Diagnostic;
      Destination_Is_Terminal : Boolean;
      No_Color_Active        : Boolean := False) return String
   is
      LF     : constant String := [1 => ASCII.LF];
      Label  : constant String := L.Label (Catalog, Item.Severity);
      Result : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String
          (Styled
             (L.Text
                (Catalog,
                 "awk.diagnostic.header",
                 "severity",
                 Label,
                 L.Primary (Catalog, Item)),
              Terminal_Styles.Role_Error,
              Destination_Is_Terminal,
              No_Color_Active));
   begin
      if Ada.Strings.Unbounded.Length (Item.Source_Name) > 0
        and then Item.Line > 0
      then
         declare
            Location : constant String :=
              Image (Item.Line)
              & (if Item.Column > 0 then ":" & Image (Item.Column) else "");
         begin
            Ada.Strings.Unbounded.Append
              (Result,
               LF & L.Text
                 (Catalog,
                  "awk.diagnostic.source_location",
                  "path",
                  Source_Display_Name
                    (Catalog, Ada.Strings.Unbounded.To_String (Item.Source_Name)),
                  Location));
         end;
      end if;
      if Ada.Strings.Unbounded.Length (Item.Detail) > 0 then
         Ada.Strings.Unbounded.Append
           (Result,
            LF & L.Text
              (Catalog,
               "awk.diagnostic.detail",
               Detail => Ada.Strings.Unbounded.To_String (Item.Detail)));
      end if;
      if Ada.Strings.Unbounded.Length (Item.Hint_Id) > 0 then
         Ada.Strings.Unbounded.Append
           (Result,
            LF & L.Text (Catalog, "awk.diagnostic.hint",
                         "detail", L.Text (Catalog, Ada.Strings.Unbounded.To_String (Item.Hint_Id))));
      end if;
      Ada.Strings.Unbounded.Append (Result, LF);
      return Ada.Strings.Unbounded.To_String (Result);
   end Diagnostic_Text;
end Awk_CLI.Output;
