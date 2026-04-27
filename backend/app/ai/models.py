import torch
import torch.nn as nn

from app.ai.labels import NUM_CLASSES
from app.ai.config import WINDOW_SIZE, NUM_JOINTS, VIDEO_FEAT_DIM


class DanceTransformer(nn.Module):
    def __init__(
        self,
        num_classes: int = NUM_CLASSES,
        num_frames: int = WINDOW_SIZE,
        num_joints: int = NUM_JOINTS,
        embed_dim: int = 128,
        depth: int = 6,
        heads: int = 8,
        dropout: float = 0.2,
    ):
        super().__init__()
        self.input_projection = nn.Linear(num_joints * 2, embed_dim)
        self.pos_embedding = nn.Parameter(torch.zeros(1, num_frames, embed_dim))

        encoder_layer = nn.TransformerEncoderLayer(
            d_model=embed_dim,
            nhead=heads,
            dim_feedforward=embed_dim * 4,
            dropout=dropout,
            activation="gelu",
            batch_first=True,
        )
        self.transformer = nn.TransformerEncoder(encoder_layer, num_layers=depth)

        self.norm = nn.LayerNorm(embed_dim)
        self.classifier = nn.Sequential(
            nn.Linear(embed_dim, 256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, num_classes),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # expected: [B, C, T, V, 1] or [B, C, T, V]
        if x.dim() == 5:
            x = x.squeeze(-1)

        b, c, t, v = x.shape
        x = x.permute(0, 2, 3, 1).reshape(b, t, -1)  # [B, T, V*C]
        x = self.input_projection(x) + self.pos_embedding
        x = self.transformer(x)
        x = self.norm(x.mean(dim=1))
        return self.classifier(x)


class LateFusionModel(nn.Module):
    def __init__(
        self,
        skeleton_backbone: nn.Module,
        num_classes: int = NUM_CLASSES,
        video_feat_dim: int = VIDEO_FEAT_DIM,
        freeze_backbone: bool = True,
    ):
        super().__init__()
        self.skeleton_backbone = skeleton_backbone

        if freeze_backbone:
            for p in self.skeleton_backbone.parameters():
                p.requires_grad = False

        self.video_proj = nn.Sequential(
            nn.Linear(video_feat_dim, 256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, 128),
            nn.ReLU(),
            nn.Dropout(0.2),
        )

        self.fusion_head = nn.Sequential(
            nn.Linear(num_classes + 128, 128),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(128, num_classes),
        )

    def forward(self, skeleton_x: torch.Tensor, video_feat: torch.Tensor) -> torch.Tensor:
        skel_logits = self.skeleton_backbone(skeleton_x)
        video_z = self.video_proj(video_feat)
        fused = torch.cat([skel_logits, video_z], dim=1)
        out = self.fusion_head(fused)
        return out