using System;
using System.Collections.Generic;
using System.IO;
using System.Web;
using System.Web.UI;

namespace WebTail
{
    public partial class Default : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
         
        }

        #region REST_api

        [System.Web.Services.WebMethod]
        public static IList<string> GetLogTail(string logname, string numrows)
        {
            var lineCnt = 1;
            var lines = new List<string>();
            int maxLines;

            if (!int.TryParse(numrows, out maxLines))
            {
                maxLines = 100;
            }
            var logFile = HttpUtility.UrlDecode(logname);
            if (!File.Exists(logFile))
            {
                lines.Add("WARN: Log File " + logFile + " Doesnt Exist Yet!");
                return lines;
            }

            var br = new BackwardReader(logFile);
            while (!br.SOF)
            {
                var line = br.Readline();
                lines.Add(line + Environment.NewLine);
                if (lineCnt == maxLines) break;
                lineCnt++;
            }
            lines.Reverse();
            return lines;
        }

        #endregion
    }
}
