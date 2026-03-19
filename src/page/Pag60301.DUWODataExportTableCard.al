page 60301 "DUWO Data Export Table Card"
{
    Caption = 'Data Export Table Card';
    PageType = Card;
    SourceTable = "DUWO Data Export Table Setup";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Table No."; Rec."Table No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the table to export.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The name of the selected table.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Whether this table is included in the export.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'A description for this export table setup.';
                }
            }
            part(Fields; "DUWO Data Export Field Subpage")
            {
                Caption = 'Fields';
                ApplicationArea = All;
                SubPageLink = "Table No." = field("Table No.");
            }
        }
    }
}
