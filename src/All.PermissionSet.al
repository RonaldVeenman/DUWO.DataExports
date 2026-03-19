permissionset 60300 "DUWO Data Export"
{
    Access = Internal;
    Assignable = true;
    Caption = 'All permissions', Locked = true;

    Permissions =
         codeunit "DUWO Azure Blob Storage Mgt." = X,
         page "DUWO Data Export Field Subpage" = X,
         page "DUWO Data Export Table Card" = X,
         page "DUWO Data Export Table List" = X,
         report "DUWO Export Tables" = X,
         table "DUWO Data Export Field Setup" = X,
         table "DUWO Data Export Table Setup" = X,
         tabledata "DUWO Data Export Field Setup" = RIMD,
         tabledata "DUWO Data Export Table Setup" = RIMD;
}