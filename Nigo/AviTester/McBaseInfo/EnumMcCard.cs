namespace McBaseInfo
{
    /// <summary>
    ///
    /// 研华板卡ID从“0”开始
    ///自制的GM91ECU网口运动板卡的板卡ID从“10”开始
    ///自制的GM04网口运动板卡的板卡ID从“20”开始
    ///自制的GM06网口运动板卡的板卡ID从“30”开始
    ///自制的can卡ID从“50”开始
    ///Scara机械手ID从“100”开始
    /// </summary>
    public enum EnumMcCard
    {
        GHJ,
        Avantech,
        GM91ECU,
        GM04,
        GM06,
        NtsCanBoard,
        VmCard
    }
}