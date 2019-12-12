locals  {
#  proxy_node_ids = "${compact(aws_instance.icpmaster.*.id)}"
  proxy_node_ids = "${compact(aws_instance.icpmaster.*.private_ip)}"
}

resource "aws_lb_target_group" "icp-console-31843" {
  name = "icpmaster-31843-tg"
  port = 31843
  protocol = "TCP"
  target_type = "ip"
  tags = "${var.default_tags}"
  vpc_id = "${data.aws_vpc.selected.id}"
}

resource "aws_lb_target_group" "icp-console-8443" {
  name = "icpmaster-8443-tg"
  port = 8443
  protocol = "TCP"
  target_type = "ip"
  tags = "${var.default_tags}"
  vpc_id = "${data.aws_vpc.selected.id}"
}

resource "aws_lb_target_group" "icp-console-9443" {
  name = "icpmaster-9443-tg"
  port = 9443
  protocol = "TCP"
  target_type = "ip"
  tags = "${var.default_tags}"
  vpc_id = "${data.aws_vpc.selected.id}"
}

resource "aws_lb_target_group" "icp-kubernetes-api-8001" {
  name = "icpmaster-8001-tg"
  port = 8001
  protocol = "TCP"
  target_type = "ip"
  tags = "${var.default_tags}"
  vpc_id = "${data.aws_vpc.selected.id}"
}

resource "aws_lb_target_group" "icp-registry-8500" {
  name = "icpmaster-8500-tg"
  port = 8500
  protocol = "TCP"
  target_type = "ip"
  tags = "${var.default_tags}"
  vpc_id = "${data.aws_vpc.selected.id}"
}

resource "aws_lb_target_group" "icp-registry-8600" {
  name = "icpmaster-8600-tg"
  port = 8600
  protocol = "TCP"
  target_type = "ip"
  tags = "${var.default_tags}"
  vpc_id = "${data.aws_vpc.selected.id}"
}

resource "aws_lb_listener" "icp-console-8443" {
  load_balancer_arn = "${aws_lb.icp-console.arn}"
  port = "8443"
  protocol = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.icp-console-8443.arn}"
    type = "forward"
  }
}

resource "aws_lb_listener" "icp-console-31843" {
  load_balancer_arn = "${aws_lb.icp-console.arn}"
  port = "31843"
  protocol = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.icp-console-31843.arn}"
    type = "forward"
  }
}

resource "aws_lb_listener" "icp-console-9443" {
  load_balancer_arn = "${aws_lb.icp-console.arn}"
  port = "9443"
  protocol = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.icp-console-9443.arn}"
    type = "forward"
  }
}


resource "aws_lb_listener" "icp-registry-8500" {
  load_balancer_arn = "${aws_lb.icp-console.arn}"
  port = "8500"
  protocol = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.icp-registry-8500.arn}"
    type = "forward"
  }
}

resource "aws_lb_listener" "icp-registry-8600" {
  load_balancer_arn = "${aws_lb.icp-console.arn}"
  port = "8600"
  protocol = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.icp-registry-8600.arn}"
    type = "forward"
  }
}

resource "aws_lb_listener" "icp-kubernetes-api-8001" {
  load_balancer_arn = "${aws_lb.icp-console.arn}"
  port = "8001"
  protocol = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.icp-kubernetes-api-8001.arn}"
    type = "forward"
  }
}

resource "aws_lb_target_group_attachment" "master-31843" {
  count = "3"
  target_group_arn = "${aws_lb_target_group.icp-console-31843.arn}"
  target_id = "${element(local.proxy_node_ids, count.index)}"
  port = 31843

}


resource "aws_lb_target_group_attachment" "master-8443" {
  count = "3"
  target_group_arn = "${aws_lb_target_group.icp-console-8443.arn}"
  target_id = "${element(local.proxy_node_ids, count.index)}"
  port = 8443

}

resource "aws_lb_target_group_attachment" "master-9443" {
#  count = "${var.master["nodes"]}"
  count = "3"
  target_group_arn = "${aws_lb_target_group.icp-console-9443.arn}"
  target_id = "${element(local.proxy_node_ids, count.index)}"
  port = 9443
}

resource "aws_lb_target_group_attachment" "master-8001" {
#  count = "${var.master["nodes"]}"
  count = "3"
  target_group_arn = "${aws_lb_target_group.icp-kubernetes-api-8001.arn}"
  target_id = "${element(local.proxy_node_ids, count.index)}"
  port = 8001

}

resource "aws_lb_target_group_attachment" "master-8500" {
#  count = "${var.master["nodes"]}"
  count = "3"
  target_group_arn = "${aws_lb_target_group.icp-registry-8500.arn}"
  target_id = "${element(local.proxy_node_ids, count.index)}"
  port = 8500
}

resource "aws_lb_target_group_attachment" "master-8600" {
#  count = "${var.master["nodes"]}"
  count = "3"
  target_group_arn = "${aws_lb_target_group.icp-registry-8600.arn}"
  target_id = "${element(local.proxy_node_ids, count.index)}"
  port = 8600
}

resource "aws_lb" "icp-console" {

  depends_on = [ 
  	"aws_instance.icpmaster", 
  	"aws_instance.icpworker"
  ]


  name = "icp-console-lb"
  load_balancer_type = "network"
  internal = "true"

  tags = "${var.default_tags}"
  
  subnets = [ "${var.subnet_ids}" ]
}

resource "aws_lb_target_group" "icp-proxy-443" {
  name = "icpproxy-443-tg"
  port = 443
  protocol = "TCP"
  target_type = "ip"
  tags = "${var.default_tags}"
  vpc_id = "${data.aws_vpc.selected.id}"
}

resource "aws_lb_target_group" "icp-proxy-80" {
  name = "icpproxy-80-tg"
  port = 80
  protocol = "TCP"
  target_type = "ip"
  tags = "${var.default_tags}"
  vpc_id = "${data.aws_vpc.selected.id}"
}

resource "aws_lb_target_group_attachment" "icp-proxy-443" {
  count = "3"
  target_group_arn = "${aws_lb_target_group.icp-proxy-443.arn}"
  target_id = "${element(local.proxy_node_ids, count.index)}"
  port = 443

}

resource "aws_lb_target_group_attachment" "icp-proxy-80" {
  count = "3"
  target_group_arn = "${aws_lb_target_group.icp-proxy-80.arn}"
  target_id = "${element(local.proxy_node_ids, count.index)}"
  port = 80

}

resource "aws_lb_listener" "icp-proxy-443" {
  load_balancer_arn = "${aws_lb.icp-console.arn}"
  port = "443"
  protocol = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.icp-proxy-443.arn}"
    type = "forward"
  }
}
resource "aws_lb_listener" "icp-proxy-80" {
  load_balancer_arn = "${aws_lb.icp-console.arn}"
  port = "80"
  protocol = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.icp-proxy-80.arn}"
    type = "forward"
  }
}

#resource "aws_lb" "icp-proxy" {
#
#  name = "icp-proxy-lb"
#  load_balancer_type = "network"
#  internal = "true"
#
#  # The same availability zone as our instance
#  subnets = [ "${var.subnet_ids}" ]
#
#  tags = "${var.default_tags}"
#}
