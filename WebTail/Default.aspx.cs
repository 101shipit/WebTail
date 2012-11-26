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
        public static IList<string> GetLogTail(string logname, string numrows, string fileLastChangedDate)
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
                lines.Add("date");
                lines.Add("date");
                lines.Add("WARN: Log File " + logFile + " Doesnt Exist Yet!");
                return lines;
            }


            var fileLastWritten = File.GetLastWriteTime(logFile);
            var fileCreatedDate = File.GetCreationTime(logFile);
            if (Convert.ToString(fileLastWritten) == fileLastChangedDate)
            {
                lines.Add(Convert.ToString(fileLastWritten));
                return lines;
            }


            using (var fs = new FileStream(logFile, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
            {
                using (var rsr = new ReverseStreamReader(fs))
                {
                    while (!rsr.Sof)
                    {
                        var line = rsr.ReadLine();
                        lines.Add(line + Environment.NewLine);
                        if (lineCnt == maxLines) break;
                        lineCnt++;
                    }
                }
            }

            lines.Add(Convert.ToString(fileCreatedDate));
            lines.Add(Convert.ToString(fileLastWritten));
            lines.Reverse();
            return lines;
        }

        #endregion
    }
}
