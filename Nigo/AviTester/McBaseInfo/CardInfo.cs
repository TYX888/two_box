using System.ComponentModel;

namespace McBaseInfo
{
    public class CardInfo : INotifyPropertyChanged
    {

        #region 接口实现

        public event PropertyChangedEventHandler PropertyChanged;

        protected virtual void SendPropertyChanged(string propertyName)
        {
            if ((this.PropertyChanged != null))
            {
                this.PropertyChanged(this, new PropertyChangedEventArgs(propertyName));
            }
        }

        #endregion

        private EnumMcCard _mcCard;
        /// <summary> 硬件类型:研华或自制can板 </summary>
        [Category("Card")]
        [Description("硬件类型:研华或自制can板")]
        [DisplayName("McCard")]
        [Browsable(true)]
        public EnumMcCard McCard
        {
            get { return _mcCard; }
            set
            {
                if (_mcCard != value)
                {
                    _mcCard = value;
                    this.SendPropertyChanged("McCard");
                }
            }
        }

        private string _cardName;
        /// <summary> 实际对应的板卡Id(名称) </summary>
        [Category("Card")]
        [Description("实际对应的板卡名称")]
        [DisplayName("CardName")]
        [Browsable(true)]
        public string CardName
        {
            get { return _cardName; }
            set
            {
                if (_cardName != value)
                {
                    _cardName = value;
                    this.SendPropertyChanged("CardName");
                }
            }
        }

        private int _cardId;
        /// <summary> 实际对应的板卡Id（0开始） </summary>
        [Category("Card")]
        [Description("实际对应的板卡Id（0开始）")]
        [DisplayName("CardId")]
        [Browsable(true)]
        public int CardId
        {
            get { return _cardId; }
            set
            {
                if (_cardId != value)
                {
                    _cardId = value;
                    this.SendPropertyChanged("CardId");
                }
            }
        }

        private string _canIP;
        /// <summary> 自制Can卡IP </summary>
        [Category("Card")]
        [Description("自制Can卡IP")]
        [DisplayName("CanIP")]
        [Browsable(true)]
        public string CanIP
        {
            get { return _canIP; }
            set
            {
                if (_canIP != value)
                {
                    _canIP = value;
                    this.SendPropertyChanged("CanIP");
                }
            }
        }

        private int _canPort;
        /// <summary> 自制Can卡port </summary>
        [Category("Card")]
        [Description("自制Can卡port")]
        [DisplayName("CanPort")]
        [Browsable(true)]
        public int CanPort
        {
            get { return _canPort; }
            set
            {
                if (_canPort != value)
                {
                    _canPort = value;
                    this.SendPropertyChanged("CanPort");
                }
            }
        }
    }
}