package webapi;

#if php
typedef Web = php.Web;
#elseif neko
typedef Web = neko.Web;
#end
