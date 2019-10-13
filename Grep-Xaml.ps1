<#
	.SYNOPSIS
	XPath式を用いてXAMLファイル内を検索します。

	.DESCRIPTION
	ここに説明を書きます。

	.EXAMPLE
	Grep-Xaml -Path *.xaml -XPath "//*[name()='Variable']"

	.PARAMETER Path
	XAMLファイルのパスを指定します。

	.PARAMETER XPath
	XPath式を指定します。
#>

[CmdletBinding(DefaultParameterSetName="Pipeline")]
Param
(
	[Parameter(ParameterSetName="Path", Position=0, Mandatory=$true)]
	[Parameter(ParameterSetName="Pipeline", ValueFromPipeline=$true)]
	[Alias("p")]
	[ValidateNotNullOrEmpty()]
	[string[]]
	$Path,

	[Parameter(ParameterSetName="Path", Position=1, Mandatory=$true)]
	[Parameter(ParameterSetName="Pipeline", Position=0, Mandatory=$true)]
	[Alias("xp")]
	[ValidateNotNullOrEmpty()]
	[string]
	$XPath,

	[Parameter(ParameterSetName="Path", Position=2)]
	[Parameter(ParameterSetName="Pipeline", Position=1)]
	[Alias("i")]
	[ValidateNotNullOrEmpty()]
	[object[]]
	$Items = @("#Path","#Name","#DisplayNamePath"),

	[Parameter(ParameterSetName="Path", Position=3)]
	[Parameter(ParameterSetName="Pipeline", Position=2)]
	[Alias("f")]
	[ValidateNotNull()]
	[ScriptBlock]
	$Filter = {$true}
)

function GetAttrValuePath
{
	Param
	(
		[Parameter(Position=0, Mandatory=$true)]
		[ValidateNotNull()]
		[System.Xml.XmlElement]
		$XmlElement,

		[Parameter(Position=1, Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Attribute,

		[Parameter(Position=2)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Separator = " > "
	)

	$list = New-Object System.Collections.ArrayList
	for ($Parent = $XmlElement.get_ParentNode(); $Parent -and $Parent -is [System.Xml.XmlElement]; $Parent = $Parent.get_ParentNode())
	{
		$attrValue = $Parent.GetAttribute($Attribute)
		if ($attrValue)
		{
			$list.Insert(0, $attrValue)
		}
	}
	return $list -join $Separator
}

function GetElementPath
{
	Param
	(
		[Parameter(Position=0, Mandatory=$true)]
		[ValidateNotNull()]
		[System.Xml.XmlElement]
		$XmlElement,

		[Parameter(Position=1)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Separator = "/"
	)

	$list = New-Object System.Collections.ArrayList
	for ($Parent = $XmlElement.get_ParentNode(); $Parent -and $Parent -is [System.Xml.XmlElement]; $Parent = $Parent.get_ParentNode())
	{
		$list.Insert(0, $Parent.get_Name())
	}
	return ($Separator + ($list -join $Separator)).Trim()
}

function FindParentElement
{
	Param
	(
		[Parameter(Position=0, Mandatory=$true)]
		[ValidateNotNull()]
		[System.Xml.XmlElement]
		$XmlElement,

		[Parameter(Position=1, Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string[]]
		$TagNames
	)

	for ($Parent = $XmlElement.get_ParentNode(); $Parent -and $Parent -is [System.Xml.XmlElement]; $Parent = $Parent.get_ParentNode())
	{
		if ($TagNames.Contains($Parent.get_Name()))
		{
			return $Parent
		}
	}
	return $null
}

$PREDEFINED_ITEMS = @{

	"#Path" = @{
		n = "#Path";
		e = { $_.Path }
	};

	"#FullPath" = @{
		n = "#FullPath";
		e = { $_.Path }
	};

	"#FileName" = @{
		n = "#FileName";
		e = { [System.IO.Path]::GetFileName($_.Path) }
	};

	"#FolderPath" = @{
		n = "#FolderPath";
		e = { [System.IO.Path]::GetDirectoryName($_.Path) }
	};

	"#ElementPath" = @{
		n = "#ElementPath";
		e = { GetElementPath $_.Node }
	};

	"#DisplayNamePath" = @{
		n = "#DisplayNamePath";
		e = { GetAttrValuePath $_.Node "DisplayName" }
	};

	"#InCommentOut" = @{
		n = "#InCommentOut";
		e = { (FindParentElement $_.Node "ui:CommentOut.Body","ui:CommentOut") -ne $null }
	};

	"#Name" = @{
		n = "#Name";
		e = { $_.Node.get_Name() }
	};

	"#Value" = @{
		n = "#Value";
		e = { $_.Node.get_Value() }
	};

	"#NodeType" = @{
		n = "#NodeType";
		e = { $_.Node.get_NodeType() }
	};

	"#ParentNode" = @{
		n = "#ParentNode";
		e = { $_.Node.get_ParentNode() }
	};

	"#InnerText" = @{
		n = "#InnerText";
		e = { $_.Node.get_InnerText() }
	};

	"#InnerXml" = @{
		n = "#InnerXml";
		e = { $_.Node.get_InnerXml() }
	};

	"#OuterXml" = @{
		n = "#OuterXml";
		e = { $_.Node.get_OuterXml() }
	};
}

$SelectItems = @()
foreach ($Item in $Items)
{
	if ($Item)
	{
		if ($Item -is [string])
		{
			$PreDefItem = $PREDEFINED_ITEMS[$Item]
			if ($PreDefItem)
			{
				$SelectItems += $PreDefItem
			}
			else
			{
				$SelectItems += iex "@{ n='$Item'; e={`$_.Node.GetAttribute('$Item')} }"
			}
		}
		elseif ($Item -is [Hashtable])
		{
			$SelectItems += $Item
		}
		else
		{
			throw "Unsupported Data Type. " + $Item.GetType().FullName
		}
	}
}

Select-Xml -Path $Path -XPath $XPath | select $SelectItems | ? $Filter




# Grep-Xaml -p Main.xaml -xp "//*[name()='Variable']" -i "#FileName","#Name","Name","x:TypeArguments","Default","#InCommentOut","#DisplayNamePath","#ElementPath" | ogv



